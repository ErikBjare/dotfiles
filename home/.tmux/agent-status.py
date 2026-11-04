#!/usr/bin/env python3
"""Event-driven OSC 7501 -> tmux pane options. No output is persisted.

Uses tmux's single pipe-pane slot; install never replaces an existing pipe.
Reports are terminal metadata, not authenticated evidence or authorization.
Only root reports are shown; child record IDs cannot overwrite pane state.
"""

import os
import re
import subprocess
import sys

SOCKET = os.environ.get("TMUX", "").split(",", 1)[0]

STATES = {"idle", "working", "done", "blocked", "error", "clear"}


class Parser:
    """Bounded OSC parser accepting BEL and ST, including split reads."""

    def __init__(self, report):
        self.report = report
        self.buffer = None
        self.escape = False

    def feed(self, data):
        for byte in data:
            if self.buffer is None:
                if self.escape and byte == 93:  # ESC ]
                    self.buffer = bytearray()
                self.escape = byte == 27
                continue
            if byte == 7 or (self.escape and byte == 92):
                payload = bytes(self.buffer)
                if byte == 92:
                    payload = payload[:-1]
                self.buffer = None
                self.escape = False
                self.parse(payload)
                continue
            if byte in (24, 26) or len(self.buffer) >= 4096:
                self.buffer = None
                self.escape = False
                continue
            self.buffer.append(byte)
            self.escape = byte == 27

    def parse(self, payload):
        if payload == b"133;A" or payload.startswith(b"133;A;"):
            # Shell prompt: clear state after an agent crashes/is killed.
            self.report("clear")
            return
        if not payload.startswith(b"7501;"):
            return
        try:
            fields = dict(
                part.split("=", 1) for part in payload[5:].decode("ascii").split(":")
            )
        except (ValueError, UnicodeDecodeError):
            return
        state = fields.get("state")
        if state in STATES and not fields.get("id"):
            self.report(state)


def tmux(*args):
    return subprocess.run(
        ["tmux", "-S", SOCKET, *args],
        capture_output=True,
        text=True,
        timeout=2,
        check=False,
    )


def watch(pane):
    previous = None

    def report(state):
        nonlocal previous
        if state == previous:
            return
        previous = state
        if state == "clear":
            tmux("set-option", "-pu", "-t", pane, "@agent-state")
        else:
            tmux("set-option", "-p", "-t", pane, "@agent-state", state)
        tmux("refresh-client", "-S")

    parser = Parser(report)
    try:
        while data := os.read(0, 8192):
            parser.feed(data)
    finally:
        report("clear")


def install():
    # Conditional runs in tmux's command queue: no check/install race.
    # -o alone TOGGLES an existing pipe off, so never use it here.
    result = tmux("list-panes", "-a", "-F", "#{pane_id}:#{pane_pipe}")
    if result.returncode:
        raise SystemExit(result.stderr)
    for line in result.stdout.splitlines():
        pane, _, piped = line.partition(":")
        if re.fullmatch(r"%\d+", pane) and piped == "0":
            tmux(
                "if-shell",
                "-F",
                "-t",
                pane,
                "#{==:#{pane_pipe},0}",
                f"pipe-pane -t {pane} "
                f'\'python3 "$HOME/.tmux/agent-status.py" --watch %{pane} "#{{socket_path}}"\'',
            )


if __name__ == "__main__":
    if (
        len(sys.argv) == 4
        and sys.argv[1] == "--watch"
        and re.fullmatch(r"%\d+", sys.argv[2])
    ):
        SOCKET = sys.argv[3]
        watch(sys.argv[2])
    elif len(sys.argv) == 3 and sys.argv[1] == "--install":
        SOCKET = sys.argv[2]
        install()
    else:
        raise SystemExit(
            "usage: agent-status.py --install SOCKET | --watch %PANE SOCKET"
        )
