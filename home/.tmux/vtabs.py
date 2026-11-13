#!/usr/bin/env python3
"""Vertical tabs for tmux: a sidebar listing sessions and windows (Herdr-lite).

Each window gets its own narrow sidebar pane on the left, so pane widths stay
stable when switching windows (a single pane that follows you around would
resize every TUI on each switch). Window labels use the full pane title
(e.g. a Claude Code session name), wrapped onto a second line rather than cut,
with the OSC 7501 agent state rolled up per window (see agent-status.py).

No daemon and no state files: the server-wide @vtabs-enabled option is the
only state. A sidebar redraws on tmux hooks (wait-for channel "vtabs"), polls
once a second while visible, and sleeps while its window is hidden.

    vtabs.py SOCKET toggle            show/hide sidebars in every window
    vtabs.py SOCKET ensure [@WINDOW]  add sidebars where missing, if enabled
    vtabs.py SOCKET tidy              after a pane exits: no sidebar-only
                                      windows, focus never left on a sidebar
    vtabs.py SOCKET fit               restore sidebar width after a resize
    vtabs.py SOCKET click %PANE Y CLIENT
    vtabs.py SOCKET render            the sidebar program (runs in the pane)

SOCKET is the tmux socket path, or - to take it from $TMUX.
"""

import os
import re
import shlex
import signal
import socket
import subprocess
import sys
import termios
import textwrap

SOCKET = ""
CHANNEL = "vtabs"
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
    "window_name window_active window_zoomed_flag window_bell_flag pane_id "
    "pane_active pane_width pane_height pane_current_command "
    "pane_current_path pane_title pane_start_command @agent-state @vtabs"
).split()
# Any sidebar in the window, or zoomed (splitting would unzoom it).
HAS_SIDEBAR = (
    "#{||:#{window_zoomed_flag},#{P:#{?#{||:#{@vtabs},"
    "#{m:*vtabs.py*,#{pane_start_command}}},1,}}}"
)
SEP = "\t"  # tmux escapes control chars in output, but not tab; titles cannot hold one
HOSTNAMES = {socket.gethostname(), socket.gethostname().split(".")[0]}


def tmux(*args, check=False):
    result = subprocess.run(
        ["tmux", "-S", SOCKET, *args], capture_output=True, text=True, timeout=5
    )
    if check and result.returncode:
        raise SystemExit(result.stderr.strip() or f"tmux {args[0]} failed")
    return result.stdout


def option(name):
    return tmux("show-options", "-gqv", name).strip()


def enabled():
    return option("@vtabs-enabled") == "on" and not option("@vtabs-suspended")


def width():
    value = option("@vtabs-width")
    return int(value) if value.isdigit() and int(value) >= 12 else 32


def snapshot():
    """All panes, in tmux order (sessions by name, windows/panes by index)."""
    fmt = SEP.join("#{%s}" % f for f in FIELDS)
    out = tmux("list-panes", "-a", "-F", fmt, check=True)
    panes = []
    for line in out.splitlines():
        values = line.split(SEP)
        if len(values) == len(FIELDS):
            pane = dict(zip(FIELDS, values))
            pane["sidebar"] = (
                bool(pane["@vtabs"])
                or "vtabs.py" in pane["pane_start_command"]  # set at split time
                or pane["pane_title"] == "vtabs"  # restored by tmux-resurrect
            )
            panes.append(pane)
    return panes


def windows(panes):
    """Group panes into {window_id: [panes]} preserving order."""
    grouped = {}
    for pane in panes:
        grouped.setdefault(pane["window_id"], []).append(pane)
    return grouped


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


def build(panes, me, cols, rows):
    """Rows of the sidebar for pane `me`: [(segments, target, selected)].

    segments are (text, sgr) pairs; target is a session/window id or None.
    All sessions are expanded; if that overflows, other sessions collapse.
    """
    sessions = {}
    for wid, wpanes in windows(panes).items():
        info = window_info(wpanes)
        if info:
            first = wpanes[0]
            info.update(
                id=wid,
                index=first["window_index"],
                active=first["window_active"] == "1",
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
            name = first["session_name"]
            head = [("▸ " if folded else "▾ ", "38;5;245")]
            head.append((name, "1" if current else "38;5;250"))
            if folded:
                head.append((f"  {len(wins)}w", "38;5;242"))
            state = rollup(w["state"] for w in wins)
            out.append((badge_right(head, state, cols), sid, False))
            if not folded:
                idx_w = max(len(w["index"]) for w in wins)
                for win in wins:
                    out.extend(window_rows(win, current, idx_w, cols))
        return out

    out = layout(False)
    if len(out) > rows:
        out = layout(True)
    if len(out) > rows:
        out = out[: rows - 1] + [([(" …", "38;5;242")], None, False)]
    return out


def badge_right(segments, state, cols):
    """Truncate segments to fit, then right-align the state glyph."""
    room = cols - 3  # leading space, gap, glyph
    fitted, used = [], 0
    for text, sgr in segments:
        if used + len(text) > room:
            text = text[: max(room - used - 1, 0)] + "…"
        fitted.append((text, sgr))
        used += len(text)
        if used >= room:
            break
    glyph, colour = BADGES.get(state, (" ", 0))
    fitted.insert(0, (" ", ""))
    fitted.append((" " * (cols - 2 - used - 1), ""))
    fitted.append((glyph, f"1;38;5;{colour}" if colour else ""))
    return fitted


def window_rows(win, current, idx_w, cols):
    selected = current and win["active"]
    idx_sgr = "38;5;203" if win["bell"] else "38;5;245"
    text_sgr = "1;38;5;255" if selected else "38;5;252"
    if selected:
        idx_sgr += ";1"
    label = win["label"]
    if win["extra"]:
        label += f" (+{win['extra']})"
    text_w = max(cols - idx_w - 5, 4)  # "▌NN " + label + " " + glyph + " "
    lines = textwrap.wrap(label, text_w, break_long_words=True) or [""]
    if len(lines) > 2:
        lines = [lines[0], lines[1][: text_w - 1] + "…"]
    glyph, colour = BADGES.get(win["state"], (" ", 0))
    out = []
    for i, line in enumerate(lines):
        idx = win["index"].rjust(idx_w) if i == 0 else " " * idx_w
        segs = [
            ("▌" if selected else " ", "38;5;39" if selected else ""),
            (idx, idx_sgr),
            (" " + line.ljust(text_w) + " ", text_sgr),
            (glyph if i == 0 else " ", f"1;38;5;{colour}" if colour else ""),
        ]
        out.append((segs, win["id"], selected))
    return out


def paint(rows, cols):
    lines = []
    for row in rows:
        segs, _, selected = row
        base = "48;5;25" if selected else "48;5;233"
        line = f"\x1b[0;{base}m"
        used = 0
        for text, sgr in segs:
            text = text[: max(cols - used, 0)]
            used += len(text)
            line += f"\x1b[0;{base}{';' + sgr if sgr else ''}m{text}"
        line += f"\x1b[0;{base}m" + " " * max(cols - used, 0)
        lines.append(line)
    return "\x1b[H" + "\x1b[0m\r\n".join(lines) + "\x1b[0m\x1b[J"


# ---------------------------------------------------------------- render


class Redraw(Exception):
    pass


def render():
    pane = os.environ["TMUX_PANE"]
    if not enabled() and not option("@vtabs-suspended"):
        tmux("kill-pane", "-t", pane)  # e.g. restored by resurrect after a toggle off
        return
    tmux("set-option", "-p", "-t", pane, "@vtabs", "1")
    tmux("set-option", "-p", "-t", pane, "window-style", "bg=colour233")
    tmux("set-option", "-p", "-t", pane, "window-active-style", "bg=colour233")
    out = sys.stdout
    # Title marks the pane for resurrect; hide cursor; no autowrap.
    out.write("\x1b]2;vtabs\x1b\\\x1b[?25l\x1b[?7l\x1b[2J")
    out.flush()
    try:
        attrs = termios.tcgetattr(0)
        attrs[3] &= ~(termios.ECHO | termios.ICANON)
        termios.tcsetattr(0, termios.TCSANOW, attrs)
    except termios.error:
        pass

    waiting = False

    def on_winch(*_):
        if waiting:
            raise Redraw

    signal.signal(signal.SIGWINCH, on_winch)
    last = None
    while True:
        try:
            panes = snapshot()
        except (SystemExit, subprocess.TimeoutExpired):
            return  # server gone
        me = next((p for p in panes if p["pane_id"] == pane), None)
        if me is None:
            return
        visible = me["window_active"] == "1" and me["session_attached"] != "0"
        if visible or last is None:
            cols, rows = int(me["pane_width"]), int(me["pane_height"])
            frame = paint(build(panes, me, cols, rows), cols)
            if frame != last:
                out.write(frame)
                out.flush()
                last = frame
        try:
            termios.tcflush(0, termios.TCIFLUSH)  # discard stray keystrokes
        except termios.error:
            pass
        proc = subprocess.Popen(
            ["tmux", "-S", SOCKET, "wait-for", CHANNEL],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        try:
            waiting = True
            proc.wait(timeout=1 if visible else 30)
        except subprocess.TimeoutExpired:
            pass
        except Redraw:
            last = ""  # size changed: force a repaint
        finally:
            waiting = False
            if proc.poll() is None:
                proc.kill()
                proc.wait()


# ---------------------------------------------------------------- commands


def signal_refresh():
    tmux("wait-for", "-S", CHANNEL)


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
    signal_refresh()


def tmux_quote(text):
    """Quote for tmux's command parser (double quotes expand $ and ~)."""
    for char in '\\"$':
        text = text.replace(char, "\\" + char)
    return f'"{text}"'


def disable():
    for pane in snapshot():
        if pane["sidebar"]:
            tmux("kill-pane", "-t", pane["pane_id"])


def toggle():
    if option("@vtabs-enabled") == "on":
        tmux("set-option", "-g", "@vtabs-enabled", "off")
        disable()
    else:
        tmux("set-option", "-g", "@vtabs-enabled", "on")
        ensure()


def tidy():
    for wpanes in windows(snapshot()).values():
        real = [p for p in wpanes if not p["sidebar"]]
        if not real:
            tmux("kill-window", "-t", wpanes[0]["window_id"])
        elif any(p["sidebar"] and p["pane_active"] == "1" for p in wpanes):
            tmux("select-pane", "-t", real[0]["pane_id"])
    signal_refresh()


def fit():
    w = str(width())
    for pane in snapshot():
        if pane["sidebar"] and pane["pane_width"] != w:
            tmux("resize-pane", "-t", pane["pane_id"], "-x", w)


def click(pane_id, y, client):
    panes = snapshot()
    me = next((p for p in panes if p["pane_id"] == pane_id), None)
    if me is None or not y.isdigit():
        return
    rows = build(panes, me, int(me["pane_width"]), int(me["pane_height"]))
    if int(y) < len(rows) and rows[int(y)][1]:
        # switch-client to a window id selects that session and window.
        tmux("switch-client", "-c", client, "-t", rows[int(y)][1])


def main(argv):
    global SOCKET
    if len(argv) < 3:
        raise SystemExit(__doc__)
    SOCKET, command, args = argv[1], argv[2], argv[3:]
    if SOCKET == "-":  # e.g. typed into a shell by tmux-resurrect
        SOCKET = os.environ.get("TMUX", "").split(",", 1)[0]
    commands = {
        "toggle": toggle,
        "ensure": ensure,
        "tidy": tidy,
        "fit": fit,
        "click": click,
        "render": render,
    }
    if command not in commands:
        raise SystemExit(__doc__)
    commands[command](*args)


if __name__ == "__main__":
    main(sys.argv)
