#!/usr/bin/env python3
"""Vertical tabs for tmux: a sidebar listing sessions and windows (Herdr-lite).

Each window gets its own narrow sidebar pane on the left, so pane widths stay
stable when switching windows (a single pane that follows you around would
resize every TUI on each switch). Window labels use the full pane title
(e.g. a Claude Code session name), wrapped onto a second line rather than cut,
with the OSC 7501 agent state rolled up per window (see agent-status.py).

A sidebar always highlights its own window, so a hidden sidebar is already
correct the moment its window is shown: switching never waits on a redraw.
Focus it (prefix+Tab, or move left into it) to navigate like choose-tree:
up/down or j/k switch windows live, 1-9 jump, Enter/Esc/Right go back,
prefix+Tab again hides the sidebars.
Mouse clicks are read by the running sidebar, not a new process.

No daemon and no state files: the server-wide @vtabs-enabled option is the
only state. A sidebar wakes on its window's wait-for channel ("vtabs-@N",
signalled by hooks), polls once a second while visible, and sleeps otherwise.

    vtabs.py SOCKET toggle            show/hide sidebars in every window
    vtabs.py SOCKET focus             show sidebars if hidden, focus this one
    vtabs.py SOCKET ensure [@WINDOW]  add sidebars where missing, if enabled
    vtabs.py SOCKET refresh           wake every sidebar (windows added/closed)
    vtabs.py SOCKET tidy              close windows left with only a sidebar
    vtabs.py SOCKET fit               restore sidebar width after a resize
    vtabs.py SOCKET render            the sidebar program (runs in the pane)

SOCKET is the tmux socket path, or - to take it from $TMUX.
"""

import fcntl
import fnmatch
import os
import re
import select
import shlex
import signal
import socket
import subprocess
import sys
import termios
import unicodedata

SOCKET = ""
SHELLS = {"sh", "bash", "zsh", "fish", "dash", "ksh", "tcsh", "nu", "xonsh"}
# Priority order and glyphs match the status-bar badge in agent-status.conf.
BADGES = {
    "blocked": ("!", 221),
    "error": ("x", 196),
    "working": ("~", 229),
    "done": ("+", 123),
    "idle": (".", 245),
}
PRIORITY = {state: i for i, state in enumerate(BADGES)}
FIELDS = (
    "session_id session_name session_attached window_id window_index "
    "window_active window_bell_flag pane_id pane_active pane_width "
    "pane_height pane_current_command pane_current_path pane_title "
    "pane_start_command @agent-state @vtabs"
).split()
# Any sidebar in the window, or zoomed (splitting would unzoom it).
# The exact command ensure() starts a sidebar with; tmux 3.5 reports it
# double-quoted. Anything looser would match e.g. "nvim vtabs.py", and
# sidebars get killed on toggle off.
START = "exec python3 *vtabs.py * render"
HAS_SIDEBAR = (
    "#{||:#{window_zoomed_flag},#{P:#{?#{||:#{@vtabs},#{||:"
    f'#{{m:{START},#{{pane_start_command}}}},#{{m:"{START}",#{{pane_start_command}}}}'
    "}},1,}}}"
)
SEP = "\t"  # tmux escapes control chars in output, but not tab; titles cannot hold one
HOSTNAMES = {socket.gethostname(), socket.gethostname().split(".")[0]}


def tmux(*args, check=False):
    result = subprocess.run(
        ["tmux", "-S", SOCKET, *args], capture_output=True, text=True, timeout=5
    )
    if check and result.returncode:
        raise SystemExit(result.stderr.strip() or f"tmux {args[0]} failed")
    return result


def option(name):
    return tmux("show-options", "-gqv", name).stdout.strip()


def enabled():
    return option("@vtabs-enabled") == "on" and not option("@vtabs-suspended")


def width():
    value = option("@vtabs-width")
    return int(value) if value.isdigit() and int(value) >= 12 else 32


def snapshot():
    """All panes, in tmux order (sessions by name, windows/panes by index)."""
    fmt = SEP.join("#{%s}" % f for f in FIELDS)
    out = tmux("list-panes", "-a", "-F", fmt, check=True).stdout
    panes = []
    for line in out.splitlines():
        values = line.split(SEP)
        if len(values) == len(FIELDS):
            pane = dict(zip(FIELDS, values))
            pane["sidebar"] = is_sidebar(pane)
            panes.append(pane)
    return panes


def is_sidebar(pane):
    # Never the title: any program can set it, and sidebars get killed.
    start = pane["pane_start_command"]
    if len(start) > 1 and start[0] == start[-1] == '"':
        start = start[1:-1]
    return bool(pane["@vtabs"]) or fnmatch.fnmatchcase(start, START)


def windows(panes, per_session=False):
    """Group panes into {window_id: [panes]} preserving order.

    per_session keys by "$session:@window" instead, a valid tmux target: a
    window linked into several sessions is listed once in each.
    """
    grouped = {}
    for pane in panes:
        key = pane["window_id"]
        if per_session:
            key = f"{pane['session_id']}:{key}"
        grouped.setdefault(key, []).append(pane)
    return grouped


def key(pane):
    return f"{pane['session_id']}:{pane['window_id']}"


# ---------------------------------------------------------------- cell widths


def char_cells(char):
    if unicodedata.combining(char):
        return 0
    return 2 if unicodedata.east_asian_width(char) in "WF" else 1


def cells(text):
    """Terminal columns `text` occupies (CJK and most emoji take two)."""
    return sum(char_cells(c) for c in text)


def clip(text, width, ellipsis=False):
    """Cut `text` to at most `width` columns, ending in … if cut and asked."""
    if cells(text) <= width:
        return text
    room = width - 1 if ellipsis else width
    out, used = "", 0
    for char in text:
        if used + char_cells(char) > room:
            break
        out += char
        used += char_cells(char)
    return out + ("…" if ellipsis and width > 0 else "")


def pad(text, width):
    return text + " " * max(width - cells(text), 0)


def wrap(text, width):
    """Greedy word wrap by columns; words wider than a line are split."""
    lines, line = [], ""
    for word in text.split():
        while cells(word) > width:
            head = clip(word, width - cells(line) - (1 if line else 0))
            if not head:
                lines.append(line)
                line = ""
                continue
            line = f"{line} {head}" if line else head
            lines.append(line)
            line, word = "", word[len(head):]
        candidate = f"{line} {word}" if line else word
        if cells(candidate) <= width:
            line = candidate
        else:
            lines.append(line)
            line = word
    if line or not lines:
        lines.append(line)
    return lines


# ---------------------------------------------------------------- labels


def pane_label(pane):
    cmd = pane["pane_current_command"]
    where = os.path.basename(pane["pane_current_path"].rstrip("/")) or "/"
    if cmd in SHELLS:
        return where  # a shell's title is usually stale (last command)
    # Drop status glyphs Claude Code/gptme prefix to the title ("✳ ", spinners).
    title = re.sub(r"^[^\w@~/(\[]+", "", pane["pane_title"]).strip()
    if title and title not in HOSTNAMES:
        return title
    return f"{cmd}:{where}"


def rollup(states):
    states = [s for s in states if s in PRIORITY]
    return min(states, key=PRIORITY.get) if states else ""


def window_info(panes):
    """Label, rolled-up state and extra pane count for one window."""
    real = [p for p in panes if not p["sidebar"]]
    if not real:
        return None
    # Represent the window by its most urgent agent, else its active pane.
    rep = min(
        real,
        key=lambda p: (
            PRIORITY.get(p["@agent-state"], len(PRIORITY)),
            p["pane_active"] != "1",
        ),
    )
    return {
        "label": pane_label(rep),
        "state": rollup(p["@agent-state"] for p in real),
        "extra": len(real) - 1,
    }


# ---------------------------------------------------------------- layout


def build(panes, me, cols, rows, focused=False):
    """Rows of the sidebar in pane `me`: [(segments, target, selected)].

    segments are (text, sgr) pairs; target is a session/window id or None.
    The selected row is the sidebar's own window. All sessions are expanded;
    if that overflows, other sessions collapse.
    """
    sessions = {}
    for wid, wpanes in windows(panes, per_session=True).items():
        info = window_info(wpanes)
        if info:
            first = wpanes[0]
            info.update(
                id=wid,
                index=first["window_index"],
                bell=first["window_bell_flag"] == "1",
            )
            sessions.setdefault(first["session_id"], (first, []))[1].append(info)

    def layout(collapse):
        out = []
        for sid, (first, wins) in sessions.items():
            current = sid == me["session_id"]
            folded = collapse and not current
            if out:
                out.append(([], None, False))
            head = [("▸ " if folded else "▾ ", "38;5;245")]
            head.append((first["session_name"], "1" if current else "38;5;250"))
            if folded:
                head.append((f"  {len(wins)}w", "38;5;242"))
            state = rollup(w["state"] for w in wins)
            out.append((badge_right(head, state, cols), sid, False))
            if not folded:
                idx_w = max(len(w["index"]) for w in wins)
                for win in wins:
                    out.extend(window_rows(win, win["id"] == key(me), idx_w, cols))
        return out

    budget = rows - 1 if focused else rows
    out = layout(False)
    if len(out) > budget:
        out = layout(True)
    if len(out) > budget:  # scroll so the selected window stays in view
        selected = next((i for i, row in enumerate(out) if row[2]), 0)
        total = len(out)
        start = max(0, min(selected - budget // 2, total - budget))
        out = out[start : start + budget]
        more = ([(" …", "38;5;242")], None, False)
        if start > 0 and not out[0][2]:
            out[0] = more
        if start + budget < total and not out[-1][2]:
            out[-1] = more
    if focused:
        hint = " ↑↓ switch  1-9 jump  ⏎ back"
        out.append(([(hint[:cols], "38;5;245")], None, False))
    return out


def own_record(panes, pane_id):
    """This pane's record; a linked window lists it once per session, so
    prefer the session where it is being viewed."""
    return max(
        (p for p in panes if p["pane_id"] == pane_id),
        key=lambda p: (p["window_active"] == "1", p["session_attached"] != "0"),
        default=None,
    )


def window_order(panes):
    """Window ids in display order (windows that have a real pane)."""
    return [k for k, wp in windows(panes, per_session=True).items() if window_info(wp)]


def badge_right(segments, state, cols):
    """Truncate segments to fit, then right-align the state glyph."""
    room = cols - 3  # leading space, gap, glyph
    fitted, used = [], 0
    for text, sgr in segments:
        if used + cells(text) > room:
            text = clip(text, max(room - used, 0), ellipsis=True)
        fitted.append((text, sgr))
        used += cells(text)
        if used >= room:
            break
    glyph, colour = BADGES.get(state, (" ", 0))
    fitted.insert(0, (" ", ""))
    fitted.append((" " * (cols - 2 - used - 1), ""))
    fitted.append((glyph, f"1;38;5;{colour}" if colour else ""))
    return fitted


def window_rows(win, selected, idx_w, cols):
    idx_sgr = "38;5;203" if win["bell"] else "38;5;245"
    text_sgr = "1;38;5;255" if selected else "38;5;252"
    if selected:
        idx_sgr += ";1"
    label = win["label"]
    if win["extra"]:
        label += f" (+{win['extra']})"
    text_w = max(cols - idx_w - 5, 4)  # "▌NN " + label + " " + glyph + " "
    lines = wrap(label, text_w)
    if len(lines) > 2:
        lines = [lines[0], clip(lines[1] + "…", text_w, ellipsis=True)]
    glyph, colour = BADGES.get(win["state"], (" ", 0))
    out = []
    for i, line in enumerate(lines):
        idx = win["index"].rjust(idx_w) if i == 0 else " " * idx_w
        segs = [
            ("▌" if selected else " ", "38;5;39" if selected else ""),
            (idx, idx_sgr),
            (" " + pad(line, text_w) + " ", text_sgr),
            (glyph if i == 0 else " ", f"1;38;5;{colour}" if colour else ""),
        ]
        out.append((segs, win["id"], selected))
    return out


def paint(rows, cols, focused):
    lines = []
    for segs, _, selected in rows:
        base = ("48;5;31" if focused else "48;5;25") if selected else "48;5;233"
        line = f"\x1b[0;{base}m"
        used = 0
        for text, sgr in segs:
            text = clip(text, max(cols - used, 0))
            used += cells(text)
            line += f"\x1b[0;{base}{';' + sgr if sgr else ''}m{text}"
        line += f"\x1b[0;{base}m" + " " * max(cols - used, 0)
        lines.append(line)
    return "\x1b[H" + "\x1b[0m\r\n".join(lines) + "\x1b[0m\x1b[J"


# ---------------------------------------------------------------- render

KEYS = re.compile(
    rb"\x1b\[<(\d+);(\d+);(\d+)([Mm])"  # SGR mouse
    rb"|\x1b\[[0-9;]*[A-Za-z~]|\x1bO[A-Za-z]"  # CSI/SS3 keys, focus in/out
    rb"|[\s\S]"
)
UP = {b"\x1b[A", b"\x1bOA", b"k"}
DOWN = {b"\x1b[B", b"\x1bOB", b"j"}
BACK = {b"\r", b"\n", b"\x1b", b"q", b"\t", b"l", b"\x1b[C", b"\x1bOC"}


class Sidebar:
    def __init__(self, pane):
        self.pane = pane
        self.panes = []
        self.me = None

    def window(self, wid):
        return windows(self.panes, per_session=True).get(wid, [])

    def go(self, wid, stay):
        """Show window `wid`; keep focus in its sidebar if `stay`."""
        target = self.window(wid)
        side = next((p for p in target if p["sidebar"]), None)
        real = [p for p in target if not p["sidebar"]]
        args = ["switch-client", "-t", wid]
        if stay and side:
            args += [";", "select-pane", "-t", side["pane_id"]]
        elif real and not any(p["pane_active"] == "1" for p in real):
            args += [";", "select-pane", "-t", real[0]["pane_id"]]
        tmux(*args)

    def back(self):
        """Return focus from the sidebar to the window's previous pane."""
        if tmux("last-pane", "-t", self.pane).returncode:
            real = [p for p in self.window(key(self.me)) if not p["sidebar"]]
            if real:
                tmux("select-pane", "-t", real[0]["pane_id"])

    def keys(self, data):
        moves, action = 0, None
        for m in KEYS.finditer(data):
            k = m.group(0)
            if m.group(1) is not None:  # mouse: left press only, no wheel/drag
                if m.group(4) == b"M" and int(m.group(1)) == 0:
                    action = ("click", int(m.group(3)) - 1)
            elif k in UP:
                moves -= 1
            elif k in DOWN:
                moves += 1
            elif k in BACK:
                action = ("back",)
            elif k.isdigit():
                action = ("jump", k.decode())
        order = window_order(self.panes)
        if moves and key(self.me) in order:
            i = order.index(key(self.me))
            self.go(order[(i + moves) % len(order)], stay=True)
        elif action and action[0] == "back":
            self.back()
        elif action and action[0] == "jump":
            index = "10" if action[1] == "0" else action[1]
            for wid, wp in windows(self.panes, per_session=True).items():
                first = wp[0]
                if first["session_id"] == self.me["session_id"] and first["window_index"] == index:
                    self.go(wid, stay=True)
        elif action and action[0] == "click":
            rows = build(self.panes, self.me, *self.size(), focused=self.focused())
            if 0 <= action[1] < len(rows) and rows[action[1]][1]:
                target = rows[action[1]][1]
                self.back()  # the click focused this sidebar; undo that
                if ":" in target:  # "$session:@window", else a session
                    if target != key(self.me):
                        self.go(target, stay=False)
                else:
                    tmux("switch-client", "-t", target)

    def size(self):
        return int(self.me["pane_width"]), int(self.me["pane_height"])

    def visible(self):
        return self.me["window_active"] == "1" and self.me["session_attached"] != "0"

    def focused(self):
        return self.visible() and self.me["pane_active"] == "1"

    def update(self):
        try:
            self.panes = snapshot()
        except (SystemExit, subprocess.TimeoutExpired):
            return False  # server gone
        self.me = own_record(self.panes, self.pane)
        return self.me is not None


def render():
    pane = os.environ["TMUX_PANE"]
    if not enabled() and not option("@vtabs-suspended"):
        tmux("kill-pane", "-t", pane)  # e.g. restored by resurrect after a toggle off
        return
    tmux(
        "set-option", "-p", "-t", pane, "@vtabs", "1", ";",
        "set-option", "-p", "-t", pane, "window-style", "bg=colour233", ";",
        "set-option", "-p", "-t", pane, "window-active-style", "bg=colour233",
    )  # fmt: skip
    out = sys.stdout
    # Title marks the pane for resurrect; hide cursor; no autowrap; SGR mouse
    # and focus reports so clicks and focus changes reach this process.
    out.write("\x1b]2;vtabs\x1b\\\x1b[?25l\x1b[?7l\x1b[?1000h\x1b[?1006h\x1b[?1004h\x1b[2J")
    out.flush()
    try:
        attrs = termios.tcgetattr(0)
        attrs[3] &= ~(termios.ECHO | termios.ICANON | termios.ISIG)
        termios.tcsetattr(0, termios.TCSANOW, attrs)
    except termios.error:
        pass
    os.set_blocking(0, False)
    wake_r, wake_w = os.pipe()
    for fd in (wake_r, wake_w):
        fcntl.fcntl(fd, fcntl.F_SETFL, os.O_NONBLOCK)
    signal.signal(signal.SIGWINCH, lambda *_: None)
    signal.set_wakeup_fd(wake_w)

    bar = Sidebar(pane)
    waiter, channel, last = None, None, None
    try:
        while bar.update():
            chan = f"vtabs-{bar.me['window_id']}"
            if waiter is None or waiter.poll() is not None or chan != channel:
                if waiter and waiter.poll() is None:
                    waiter.kill()
                    waiter.wait()
                channel = chan
                waiter = subprocess.Popen(
                    ["tmux", "-S", SOCKET, "wait-for", channel],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                )
            focused = bar.focused()
            frame = paint(build(bar.panes, bar.me, *bar.size(), focused), bar.size()[0], focused)
            if frame != last:
                out.write(frame)
                out.flush()
                last = frame
            ready = select.select(
                [0, waiter.stdout, wake_r], [], [], 1 if bar.visible() else None
            )[0]
            if 0 in ready:
                try:
                    data = os.read(0, 4096)
                except BlockingIOError:
                    data = b""
                if data:
                    bar.keys(data)
            if waiter.stdout in ready:
                waiter.stdout.read()
                waiter.wait()
            if wake_r in ready:
                os.read(wake_r, 512)
                last = None  # resized: repaint
    finally:
        if waiter and waiter.poll() is None:
            waiter.kill()


# ---------------------------------------------------------------- commands


def refresh():
    """Wake every sidebar, e.g. after windows were added or closed."""
    ids = {p["window_id"] for p in snapshot() if p["sidebar"]}
    args = []
    for wid in sorted(ids):
        args += ["wait-for", "-S", f"vtabs-{wid}", ";"]
    if args:
        tmux(*args[:-1])


def ensure(target=None):
    if not enabled():
        return
    script = shlex.quote(os.path.abspath(__file__))
    cmd = f"exec python3 {script} {shlex.quote(SOCKET)} render"
    split = f"split-window -fhbd -l {width()} -t "
    for wid, wpanes in windows(snapshot()).items():
        if target and wid != target:
            continue
        if any(p["sidebar"] for p in wpanes):
            continue
        # Check and split in one queued tmux command: hooks and config
        # reloads can run ensure concurrently. -f full height, -h left/right,
        # -b on the left, -d keep focus.
        tmux("if-shell", "-F", "-t", wid, HAS_SIDEBAR, "", split + f"{wid} {tmux_quote(cmd)}")
    refresh()


def tmux_quote(text):
    """Quote for tmux's command parser (double quotes expand $ and ~)."""
    for char in '\\"$':
        text = text.replace(char, "\\" + char)
    return f'"{text}"'


def toggle():
    if option("@vtabs-enabled") == "on":
        tmux("set-option", "-g", "@vtabs-enabled", "off")
        for pane in snapshot():
            if pane["sidebar"]:
                tmux("kill-pane", "-t", pane["pane_id"])
    else:
        tmux("set-option", "-g", "@vtabs-enabled", "on")
        ensure()


def focus():
    """Show sidebars if hidden, then focus the current window's sidebar."""
    if option("@vtabs-enabled") != "on":
        tmux("set-option", "-g", "@vtabs-enabled", "on")
        ensure()
    tmux("select-pane", "-t", "{top-left}")


def tidy():
    for wpanes in windows(snapshot()).values():
        if not any(not p["sidebar"] for p in wpanes):
            tmux("kill-window", "-t", wpanes[0]["window_id"])
    refresh()


def fit():
    w = str(width())
    for pane in snapshot():
        if pane["sidebar"] and pane["pane_width"] != w:
            tmux("resize-pane", "-t", pane["pane_id"], "-x", w)


def main(argv):
    global SOCKET
    if len(argv) < 3:
        raise SystemExit(__doc__)
    SOCKET, command, args = argv[1], argv[2], argv[3:]
    if SOCKET == "-":  # e.g. typed into a shell by tmux-resurrect
        SOCKET = os.environ.get("TMUX", "").split(",", 1)[0]
    commands = {
        "toggle": toggle,
        "focus": focus,
        "ensure": ensure,
        "refresh": refresh,
        "tidy": tidy,
        "fit": fit,
        "render": render,
    }
    if command not in commands:
        raise SystemExit(__doc__)
    commands[command](*args)


if __name__ == "__main__":
    main(sys.argv)
