"""Vertical tabs sidebar (home/.tmux/vtabs.py + vtabs.conf).

Run with python3 -m unittest discover -s tests. Each server test starts its own
tmux server on a private socket with vtabs.conf loaded; mouse tests attach a
client through a pty. No live tmux is touched.
"""

import fcntl
import os
import pty
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "home/.tmux/vtabs.py"
CONF = ROOT / "home/.tmux/vtabs.conf"

sys.path.insert(0, str(SCRIPT.parent))
import vtabs  # noqa: E402


def pane(**kw):
    base = dict(
        session_id="$0",
        session_name="main",
        session_attached="1",
        window_id="@1",
        window_index="1",
        window_name="w",
        window_active="1",
        window_zoomed_flag="0",
        window_bell_flag="0",
        pane_id="%1",
        pane_active="1",
        pane_width="32",
        pane_height="20",
        pane_current_command="claude",
        pane_current_path="/home/u/proj",
        pane_title="",
        sidebar=False,
    )
    base["@agent-state"] = kw.pop("state", "")
    base.update(kw)
    return base


def text(rows):
    return ["".join(t for t, _ in segs).rstrip() for segs, _, _ in rows]


class LayoutTests(unittest.TestCase):
    def test_labels(self):
        self.assertEqual(
            vtabs.pane_label(pane(pane_title="✳ Tmux vertical tabs plugin")),
            "Tmux vertical tabs plugin",
        )
        # A shell's title is stale (last command): show the directory.
        self.assertEqual(
            vtabs.pane_label(pane(pane_current_command="fish", pane_title="git pull")),
            "proj",
        )
        host = next(iter(vtabs.HOSTNAMES))
        self.assertEqual(vtabs.pane_label(pane(pane_title=host)), "claude:proj")
        self.assertEqual(
            vtabs.pane_label(pane(pane_current_command="ssh", pane_title="~ @ node1")),
            "~ @ node1",
        )

    def test_window_uses_most_urgent_pane_and_rolls_up(self):
        info = vtabs.window_info(
            [
                pane(pane_id="%0", sidebar=True),
                pane(pane_id="%1", pane_title="editor", state="idle"),
                pane(pane_id="%2", pane_active="0", pane_title="agent", state="blocked"),
            ]
        )
        self.assertEqual(info, {"label": "agent", "state": "blocked", "extra": 1})
        self.assertIsNone(vtabs.window_info([pane(sidebar=True)]))

    def test_build_wraps_full_titles_and_marks_current(self):
        title = "Bob inventory, review, and self-improvement"
        panes = [
            pane(pane_id="%0", sidebar=True),
            pane(pane_id="%1", pane_title=title, state="working"),
            pane(
                window_id="@2",
                window_index="2",
                window_active="0",
                pane_id="%2",
                pane_title="Sound hooks",
                state="done",
            ),
        ]
        rows = vtabs.build(panes, panes[0], 32, 20)
        lines = text(rows)
        self.assertEqual(lines[0], " ▾ main                       ~")
        self.assertEqual(lines[1], "▌1 Bob inventory, review, and ~")
        self.assertEqual(lines[2], "▌  self-improvement")
        self.assertEqual(lines[3], " 2 Sound hooks                +")
        self.assertEqual([r[1] for r in rows], ["$0", "@1", "@1", "@2"])
        self.assertEqual([r[2] for r in rows], [False, True, True, False])
        for line in lines:
            self.assertLessEqual(len(line), 32)

    def test_other_sessions_collapse_when_too_tall(self):
        panes = [pane(pane_id="%0", sidebar=True), pane(pane_id="%1")]
        for i in range(10):
            panes.append(
                pane(
                    session_id="$1",
                    session_name="work",
                    window_id=f"@{10 + i}",
                    window_index=str(i),
                    pane_id=f"%{10 + i}",
                    state="blocked" if i == 3 else "",
                )
            )
        lines = text(vtabs.build(panes, panes[0], 32, 6))
        self.assertEqual(lines[-1], " ▸ work  10w                  !")
        self.assertEqual(len(lines), 4)
        self.assertEqual(len(vtabs.build(panes, panes[0], 32, 2)), 2)


@unittest.skipUnless(shutil.which("tmux"), "tmux not installed")
class ServerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.sock = os.path.join(self.tmp, "s")
        conf = Path(self.tmp, "vtabs.conf")
        conf.write_text(CONF.read_text().replace("~/.tmux/vtabs.py", str(SCRIPT)))
        Path(self.tmp, "main.conf").write_text(
            f"set -g mouse on\nset -g base-index 1\nsource {conf}\n"
        )
        self.tmux(
            "-f", os.path.join(self.tmp, "main.conf"),
            "new-session", "-d", "-s", "main", "-x", "120", "-y", "30", "sleep 600",
        )  # fmt: skip
        self.addCleanup(self.tmux, "kill-server")
        self.tmux("new-window", "-t", "main", "sleep 600")
        self.tmux("select-window", "-t", "main:1")

    def tmux(self, *args):
        return subprocess.run(
            ["tmux", "-S", self.sock, *args], capture_output=True, text=True
        ).stdout.strip()

    def vtabs(self, *args):
        subprocess.run([sys.executable, str(SCRIPT), self.sock, *args], check=True)

    def panes(self, target="main:1"):
        out = self.tmux(
            "list-panes", "-t", target, "-F",
            "#{pane_id} #{?#{||:#{@vtabs},#{m:*vtabs.py*,#{pane_start_command}}},side,main}"
            " #{pane_active} #{pane_width}",
        )  # fmt: skip
        return [line.split() for line in out.splitlines()]

    def wait_for(self, check, timeout=5):
        end = time.time() + timeout
        while time.time() < end:
            if check():
                return
            time.sleep(0.1)
        self.fail("condition not met")

    def sidebar(self, target="main:1"):
        return next(p[0] for p in self.panes(target) if p[1] == "side")

    def test_toggle_adds_and_removes_sidebars_without_stealing_focus(self):
        self.vtabs("toggle")
        for window in ("main:1", "main:2"):
            kinds = [(p[1], p[2], p[3]) for p in self.panes(window)]
            self.assertEqual(kinds[0], ("side", "0", "32"))
            self.assertEqual(kinds[1][:2], ("main", "1"))
        self.wait_for(lambda: "▾ main" in self.tmux("capture-pane", "-p", "-t", self.sidebar()))
        self.vtabs("toggle")
        self.wait_for(lambda: [p[1] for p in self.panes()] == ["main"])
        self.assertEqual(self.tmux("show", "-gv", "@vtabs-enabled"), "off")

    def test_hooks_new_window_focus_bounce_and_tidy(self):
        self.vtabs("toggle")
        self.tmux("new-window", "-t", "main", "sleep 600")
        self.wait_for(lambda: [p[1] for p in self.panes("main:3")] == ["side", "main"])
        # Navigating into the sidebar bounces focus back.
        self.tmux("select-pane", "-t", self.sidebar("main:3"))
        self.assertEqual([p[2] for p in self.panes("main:3")], ["0", "1"])
        # Closing the last real pane closes the window, not leaving a sidebar.
        main = self.panes("main:3")[1][0]
        self.tmux("kill-pane", "-t", main)
        self.wait_for(lambda: self.tmux("list-windows", "-t", "main", "-F", "#I") == "1\n2")
        # Width is restored after the window resizes.
        self.tmux("resize-window", "-t", "main:1", "-x", "160")
        self.wait_for(lambda: self.panes()[0][3] == "32")

    def test_mouse_click_switches_window_without_focusing_sidebar(self):
        self.tmux("set", "-g", "pane-border-status", "off")
        self.vtabs("toggle")
        pid, fd = pty.fork()
        if pid == 0:
            os.environ["TERM"] = "xterm-256color"
            os.execvp("tmux", ["tmux", "-S", self.sock, "attach", "-t", "main"])
        self.addCleanup(os.waitpid, pid, 0)
        self.addCleanup(os.kill, pid, 9)
        fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))

        def drain(seconds):
            end = time.time() + seconds
            while time.time() < end:
                if select.select([fd], [], [], 0.05)[0]:
                    try:
                        os.read(fd, 65536)
                    except OSError:
                        return

        drain(1.5)
        # Sidebar line 2 (terminal row 3, 1-based) is window 2.
        os.write(fd, b"\x1b[<0;5;3M\x1b[<0;5;3m")
        self.wait_for(lambda: self.tmux("display", "-p", "#I") == "2")
        drain(0.5)
        self.assertEqual(self.tmux("display", "-p", "#{?@vtabs,side,main}"), "main")
        # The newly visible sidebar redraws with window 2 selected.
        self.wait_for(
            lambda: "▌2" in self.tmux("capture-pane", "-p", "-t", self.sidebar("main:2"))
        )


if __name__ == "__main__":
    unittest.main()
