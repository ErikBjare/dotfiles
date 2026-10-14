#!/usr/bin/env python3
"""Claude Code status line (erb's personal config).

Line 1: model·effort │ dir ⎇ branch │ context % │ cost │ +/- lines │ duration
Line 2: session name │ 👁 eye time · turns · steps ($/step) · tool-call summary │ prompt-cache state

Reads the status JSON on stdin. Turn/step/tool counts come from tailing the transcript
incrementally (offset cached per session), so renders stay cheap on long sessions.
Debug: the last input is saved to /tmp/claude-statusline-input.json.

Eye time = not-AFK time with this session's pane focused, from ActivityWatch. Claude Code
sets the pane title to "<spinner> <session_name>", which tmux passes into the terminal
window title as "[#S] <title> (<path>)" (see ~/.tmux/master.conf), so we match on that.
The AW query takes ~0.4s over a multi-day session, so it is refreshed in a detached
background process at most every EYE_TTL seconds and renders read the cached value.
"""

import json
import os
import socket
import subprocess
import sys
import time
import urllib.request
from collections import Counter

CACHE_DIR = os.path.join(os.environ.get("TMPDIR", "/tmp"), "claude-statusline")
AW_URL = os.environ.get("AW_URL", "http://localhost:5600")
EYE_TTL = 60


def c(code: int, s: str, bold: bool = False) -> str:
    return f"\033[{'1;' if bold else ''}38;5;{code}m{s}\033[0m"


DIM = 244
SEP = c(238, " │ ")


def ctx_color(pct: float) -> int:
    if pct < 40:
        return 78  # green
    if pct < 60:
        return 149  # lime
    if pct < 75:
        return 220  # yellow
    if pct < 90:
        return 208  # orange
    return 196  # red


def tokens(n: float) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M".replace(".0M", "M")
    if n >= 1000:
        return f"{n / 1000:.0f}k"
    return str(int(n))


def duration(ms: float) -> str:
    s = int(ms / 1000)
    d, s = divmod(s, 86400)
    h, s = divmod(s, 3600)
    m, _ = divmod(s, 60)
    if d:
        return f"{d}d{h}h"
    if h:
        return f"{h}h{m:02d}m"
    return f"{m}m"


def cost_color(usd: float) -> int:
    if usd < 1:
        return 114
    if usd < 5:
        return 186
    if usd < 20:
        return 215
    if usd < 50:
        return 209
    return 197


def git_info(cwd: str) -> str:
    try:
        out = subprocess.run(
            # no-optional-locks: don't contend for index.lock with the agent's own git calls;
            # ignore dirty submodules: scanning them made this ~0.6s on activitywatch
            ["git", "--no-optional-locks", "-C", cwd, "status", "--porcelain=v1",
             "--branch", "--no-ahead-behind", "--ignore-submodules=dirty"],
            capture_output=True, text=True, timeout=1,
        )
        if out.returncode != 0:
            return ""
        lines = out.stdout.splitlines()
        head = lines[0][3:] if lines else ""
        branch = head.split("...")[0].replace("No commits yet on ", "")
        dirty = len(lines) - 1
        s = c(141, f"⎇ {branch}")
        if dirty:
            s += c(203, f" ●{dirty}")
        return s
    except Exception:
        return ""


CACHE_VERSION = 4


def is_prompt(entry: dict) -> int:
    """+1 for a user prompt, -1 to retract a local slash command, else 0.

    Local commands (/model, /config) log `<command-name>` then `<local-command-stdout>`;
    skill commands (/journal) log `<command-name>` and no stdout, so they stay counted.
    """
    if entry.get("type") != "user" or entry.get("isMeta") or entry.get("isSidechain"):
        return 0
    if entry.get("isCompactSummary"):
        return 0
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, list):
        if any(isinstance(b, dict) and b.get("type") == "tool_result" for b in content):
            return 0
        content = next((b.get("text", "") for b in content if isinstance(b, dict) and b.get("type") == "text"), "")
    if not isinstance(content, str):
        return 0
    text = content.lstrip()
    if text.startswith("<local-command-stdout>"):
        return -1
    if text.startswith((
        "<local-command-caveat>", "<local-command-stderr>",  # local slash-command output
        "<task-notification>",  # background agent/shell finished (not a human turn)
        "<bash-input>", "<bash-stdout>", "<bash-stderr>",  # `!` shell passthrough
        "[Request interrupted",
    )):
        return 0
    return 1


def transcript_stats(session_id: str, transcript: str) -> tuple[int, int, Counter]:
    """Count user turns, steps (model API calls) and tool_use blocks, reading only new
    bytes since last render. One assistant message is split over several lines (one per
    content block) sharing a message id, so steps count distinct ids."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache_path = os.path.join(CACHE_DIR, f"{session_id}.json")
    state = {"v": CACHE_VERSION, "offset": 0, "counts": {}, "turns": 0, "steps": 0,
             "last_id": None, "path": transcript}
    try:
        with open(cache_path) as f:
            loaded = json.load(f)
        if loaded.get("path") == transcript and loaded.get("v") == CACHE_VERSION:
            state = loaded
    except Exception:
        pass
    counts = Counter(state["counts"])
    turns, steps, last_id = state["turns"], state["steps"], state["last_id"]
    try:
        size = os.path.getsize(transcript)
        if size < state["offset"]:  # rewritten/truncated: rescan
            state["offset"], counts, turns, steps, last_id = 0, Counter(), 0, 0, None
        if size > state["offset"]:
            with open(transcript, "rb") as f:
                f.seek(state["offset"])
                chunk = f.read()
            end = chunk.rfind(b"\n") + 1  # only consume complete lines
            for line in chunk[:end].splitlines():
                is_user = b'"type":"user"' in line
                if not is_user and b'"type":"assistant"' not in line:
                    continue
                try:
                    entry = json.loads(line)
                except Exception:
                    continue
                if is_user:
                    turns = max(0, turns + is_prompt(entry))
                    continue
                msg = entry.get("message", {})
                if entry.get("type") != "assistant" or entry.get("isSidechain") or not isinstance(msg, dict):
                    continue
                if msg.get("id") and msg["id"] != last_id:
                    steps, last_id = steps + 1, msg["id"]
                content = msg.get("content") if isinstance(msg, dict) else None
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            counts[block.get("name", "?")] += 1
            state["offset"] += end
            state.update(counts=dict(counts), turns=turns, steps=steps, last_id=last_id)
            with open(cache_path, "w") as f:
                json.dump(state, f)
    except Exception:
        pass
    return turns, steps, counts


def tools_summary(counts: Counter) -> str:
    total = sum(counts.values())
    if not total:
        return ""
    groups = Counter()
    for name, n in counts.items():
        if name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
            groups["edit"] += n
        elif name == "Bash":
            groups["bash"] += n
        elif name in ("Read", "Grep", "Glob"):
            groups["read"] += n
        elif name in ("Agent", "Task", "Workflow"):
            groups["agent"] += n
        elif name.startswith("mcp__"):
            groups["mcp"] += n
        elif name in ("WebFetch", "WebSearch"):
            groups["web"] += n
    colors = {"edit": 214, "bash": 81, "read": 110, "agent": 177, "mcp": 179, "web": 75}
    parts = [c(colors[k], f"{k} {n}") for k, n in groups.most_common()]
    return c(DIM, f"⚒ {total} ") + c(DIM, "·").join(parts) if parts else c(DIM, f"⚒ {total}")


def cache_info(pc: dict) -> str:
    if not pc or not pc.get("caching_observed"):
        return ""
    if pc.get("warm"):
        left = pc.get("expires_at", 0) - time.time()
        return c(80, f"cache ✓ {duration(left * 1000)}") if left > 0 else c(80, "cache ✓")
    recache = pc.get("recache_tokens_if_cold")
    return c(111, "cache ❄ cold") + (c(DIM, f" ({tokens(recache)} to rewrite)") if recache else "")


def aw_title_regex(name: str) -> str:
    # AW's query parser rejects backslashes, so escape regex specials as [x] classes
    out = "".join(f"[{ch}]" if ch in ".^$*+?{}()|[" else ("." if ch in "]\\" else ch) for ch in name)
    return f" {out} [(]"


def eye_time_query(session_name: str, start: float, out_path: str) -> None:
    """Query AW for focused, not-AFK time on this session's window and write it to out_path."""
    host = socket.gethostname()
    period = "/".join(time.strftime("%Y-%m-%dT%H:%M:%S+00:00", time.gmtime(t)) for t in (start, time.time() + 60))
    query = [
        f'w = flood(query_bucket("aw-watcher-window_{host}"));',
        f'a = filter_keyvals(flood(query_bucket("aw-watcher-afk_{host}")), "status", ["not-afk"]);',
        f'w = filter_keyvals_regex(w, "title", {json.dumps(aw_title_regex(session_name))});',
        "w = filter_period_intersect(w, a);",
        "RETURN = sum_durations(w);",
    ]
    body = json.dumps({"timeperiods": [period], "query": query}).encode()
    req = urllib.request.Request(f"{AW_URL}/api/0/query/", body, {"Content-Type": "application/json"})
    try:
        secs = json.load(urllib.request.urlopen(req, timeout=10))[0]
    except Exception:
        secs = None
    with open(out_path, "w") as f:
        json.dump({"name": session_name, "secs": secs, "at": time.time()}, f)


def eye_time(session_id: str, session_name: str, duration_ms: float) -> float | None:
    """Cached eye time; kicks off a background refresh when stale. Never blocks on AW."""
    path = os.path.join(CACHE_DIR, f"{session_id}.eye.json")
    cached = {}
    try:
        with open(path) as f:
            cached = json.load(f)
    except Exception:
        pass
    fresh = cached.get("name") == session_name and time.time() - cached.get("at", 0) < EYE_TTL
    if not fresh:
        # touch first so concurrent renders don't spawn duplicate refreshes
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(path, "w") as f:
            json.dump({**cached, "name": session_name, "at": time.time()}, f)
        start = time.time() - duration_ms / 1000 - 60
        subprocess.Popen(
            [sys.executable, __file__, "--eye", session_name, str(start), path],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    return cached.get("secs") if cached.get("name") == session_name else None


def main() -> None:
    if len(sys.argv) == 5 and sys.argv[1] == "--eye":
        eye_time_query(sys.argv[2], float(sys.argv[3]), sys.argv[4])
        return
    raw = sys.stdin.read()
    try:
        with open("/tmp/claude-statusline-input.json", "w") as f:
            f.write(raw)
        data = json.loads(raw)
    except Exception:
        data = {}

    model = data.get("model", {}).get("display_name", "?")
    effort = (data.get("effort") or {}).get("level")
    m = c(213, model, bold=True)
    if effort:
        m += c(DIM, f"·{effort}")
    if data.get("fast_mode"):
        m += c(226, " ⚡")

    cwd = data.get("workspace", {}).get("current_dir") or data.get("cwd") or os.getcwd()
    home = os.path.expanduser("~")
    short = cwd.replace(home, "~", 1) if cwd.startswith(home) else cwd
    if len(short) > 32:
        short = "…/" + "/".join(short.split("/")[-2:])
    loc = c(39, short)
    git = git_info(cwd)
    if git:
        loc += " " + git

    line1 = [m, loc]

    ctx = data.get("context_window") or {}
    pct = ctx.get("used_percentage")
    if pct is not None:
        size = ctx.get("context_window_size") or 0
        usage = ctx.get("current_usage") or {}
        used = sum(usage.get(k, 0) for k in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"))
        s = c(ctx_color(pct), f"{pct:.0f}%", bold=True)
        if size:
            s += c(DIM, f" {tokens(used)}/{tokens(size)}")
        line1.append(s)

    cost = data.get("cost") or {}
    usd = cost.get("total_cost_usd")
    if usd is not None:
        line1.append(c(cost_color(usd), f"${usd:.2f}", bold=True))
    added, removed = cost.get("total_lines_added", 0), cost.get("total_lines_removed", 0)
    if added or removed:
        line1.append(c(78, f"+{added}") + " " + c(203, f"−{removed}"))
    if cost.get("total_duration_ms"):
        dur = c(DIM, "⏱ " + duration(cost["total_duration_ms"]))
        if cost.get("total_api_duration_ms"):
            dur += c(238, f" (api {duration(cost['total_api_duration_ms'])})")
        line1.append(dur)

    line2 = []
    if data.get("session_name"):
        line2.append(c(252, f"“{data['session_name']}”"))
    if data.get("session_id") and data.get("transcript_path"):
        turns, steps, counts = transcript_stats(data["session_id"], data["transcript_path"])
        stats = []
        if data.get("session_name") and cost.get("total_duration_ms"):
            secs = eye_time(data["session_id"], data["session_name"], cost["total_duration_ms"])
            if secs:
                stats.append(c(219, f"👁 {duration(secs * 1000)}", bold=True))
        if turns:
            stats.append(c(117, f"↻ {turns} turn{'s' if turns != 1 else ''}", bold=True))
        if steps:
            st = c(153, f"⇢ {steps} steps")
            usd = (data.get("cost") or {}).get("total_cost_usd")
            if usd:
                st += c(DIM, f" ${usd / steps:.3f}/step" if usd / steps < 0.1 else f" ${usd / steps:.2f}/step")
            stats.append(st)
        ts = tools_summary(counts)
        if ts:
            stats.append(ts)
        if stats:
            line2.append(c(DIM, " · ").join(stats))
    ci = cache_info(data.get("prompt_cache") or {})
    if ci:
        line2.append(ci)

    print(SEP.join(line1))
    if line2:
        print(SEP.join(line2))


if __name__ == "__main__":
    main()
