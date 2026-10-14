#!/usr/bin/env python3
"""Claude Code status line (erb's personal config).

Line 1: model·effort │ dir ⎇ branch │ context % │ cost │ +/- lines │ duration
Line 2: session name │ tool-call summary │ prompt-cache state

Reads the status JSON on stdin. Tool counts come from tailing the transcript
incrementally (offset cached per session), so renders stay cheap on long sessions.
Debug: the last input is saved to /tmp/claude-statusline-input.json.
"""

import json
import os
import subprocess
import sys
import time
from collections import Counter

CACHE_DIR = os.path.join(os.environ.get("TMPDIR", "/tmp"), "claude-statusline")


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


def tool_counts(session_id: str, transcript: str) -> Counter:
    """Count tool_use blocks in the transcript, reading only new bytes since last render."""
    os.makedirs(CACHE_DIR, exist_ok=True)
    cache_path = os.path.join(CACHE_DIR, f"{session_id}.json")
    state = {"offset": 0, "counts": {}, "path": transcript}
    try:
        with open(cache_path) as f:
            loaded = json.load(f)
        if loaded.get("path") == transcript:
            state = loaded
    except Exception:
        pass
    counts = Counter(state["counts"])
    try:
        size = os.path.getsize(transcript)
        if size < state["offset"]:  # rewritten/truncated: rescan
            state["offset"], counts = 0, Counter()
        if size > state["offset"]:
            with open(transcript, "rb") as f:
                f.seek(state["offset"])
                chunk = f.read()
            end = chunk.rfind(b"\n") + 1  # only consume complete lines
            for line in chunk[:end].splitlines():
                if b'"tool_use"' not in line:
                    continue
                try:
                    msg = json.loads(line).get("message", {})
                except Exception:
                    continue
                content = msg.get("content") if isinstance(msg, dict) else None
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "tool_use":
                            counts[block.get("name", "?")] += 1
            state["offset"] += end
            state["counts"] = dict(counts)
            with open(cache_path, "w") as f:
                json.dump(state, f)
    except Exception:
        pass
    return counts


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


def main() -> None:
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
        ts = tools_summary(tool_counts(data["session_id"], data["transcript_path"]))
        if ts:
            line2.append(ts)
    ci = cache_info(data.get("prompt_cache") or {})
    if ci:
        line2.append(ci)

    print(SEP.join(line1))
    if line2:
        print(SEP.join(line2))


if __name__ == "__main__":
    main()
