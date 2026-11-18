"""Vertical tabs sidebar (home/.tmux/vtabs.py + vtabs.conf).

Run with python3 -m unittest discover -s tests. Each server test starts its own
tmux server on a private socket with vtabs.conf loaded; mouse tests attach a
client through a pty. No live tmux is touched.
"""

import fcntl
import os
import pty
import select
import shlex
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
from pathlib import Path
from unittest.mock import patch

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
        pane_start_command="",
        sidebar=False,
    )
    base["@vtabs"] = ""
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
        self.assertEqual([r[1] for r in rows], ["$0", "$0:@1", "$0:@1", "$0:@2"])
        self.assertEqual([r[2] for r in rows], [False, True, True, False])
        for line in lines:
            self.assertLessEqual(len(line), 32)

    def test_wide_characters_wrap_by_terminal_cells(self):
        panes = [pane(pane_id="%0", sidebar=True), pane(pane_title="界" * 20, state="done")]
        lines = text(vtabs.build(panes, panes[0], 32, 20))
        for line in lines:
            self.assertLessEqual(vtabs.cells(line), 32)
        self.assertTrue(lines[1].endswith("+"))  # the badge survives
        self.assertEqual(lines[1].count("界") + lines[2].count("界"), 20)
        self.assertEqual(vtabs.wrap("ab " + "x" * 9, 4), ["ab x", "xxxx", "xxxx"])

    def test_linked_window_is_listed_in_each_session(self):
        panes = [
            pane(pane_id="%0", sidebar=True),
            pane(pane_id="%1", pane_title="shared"),
            pane(session_id="$1", session_name="b", pane_id="%0", sidebar=True),
            pane(session_id="$1", session_name="b", pane_id="%1", pane_title="shared"),
        ]
        rows = vtabs.build(panes, panes[0], 32, 20)
        self.assertEqual([r[1] for r in rows if r[1]], ["$0", "$0:@1", "$1", "$1:@1"])
        # The sidebar takes its context from the session viewing it.
        panes[0]["window_active"] = "0"
        self.assertEqual(vtabs.own_record(panes, "%0")["session_id"], "$1")
        self.assertNotIn("(+", "".join(text(rows)))

    def test_title_alone_does_not_make_a_sidebar(self):
        # Any program can set its title; sidebars are killed on toggle off.
        self.assertFalse(vtabs.is_sidebar(pane(pane_title="vtabs")))
        self.assertTrue(vtabs.is_sidebar(pane(**{"@vtabs": "1"})))
        start = "exec python3 /h/.tmux/vtabs.py /s render"
        self.assertTrue(vtabs.is_sidebar(pane(pane_start_command=start)))
        self.assertTrue(vtabs.is_sidebar(pane(pane_start_command=f'"{start}"')))
        for cmd in ["nvim vtabs.py", '"sleep 600 # vtabs.py"', "less vtabs.py.orig"]:
            self.assertFalse(vtabs.is_sidebar(pane(pane_start_command=cmd)), cmd)

    def test_selected_window_stays_in_view_when_overflowing(self):
        panes = [pane(window_id=f"@{i}", window_index=str(i), pane_id=f"%{10 + i}") for i in range(20)]
        panes.append(pane(pane_id="%0", window_id="@15", sidebar=True))
        rows = vtabs.build(panes, panes[-1], 32, 8)
        self.assertEqual(len(rows), 8)
        self.assertTrue(any(r[2] for r in rows))
        self.assertEqual(text(rows)[0], " …")
        self.assertEqual(text(rows)[-1], " …")

    def test_one_row_sidebar_keeps_selected_window(self):
        panes = [pane(pane_id="%0", sidebar=True), pane(pane_id="%1")]
        for focused in (False, True):
            with self.subTest(focused=focused):
                rows = vtabs.build(panes, panes[0], 32, 1, focused=focused)
                self.assertEqual(len(rows), 1)
                self.assertTrue(rows[0][2])

    def test_session_and_window_badges_share_a_column(self):
        for cols in (12, 32, 40):
            panes = [pane(pane_id="%0", sidebar=True), pane(state="done")]
            rows = vtabs.build(panes, panes[0], cols, 20)
            positions = [vtabs.cells(line.split("+")[0]) for line in text(rows) if "+" in line]
            self.assertEqual(positions, [cols - 2, cols - 2])

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


class InputTests(unittest.TestCase):
    def setUp(self):
        self.bar = vtabs.Sidebar("%0")
        self.bar.panes = [
            pane(pane_id="%0", sidebar=True), pane(pane_id="%1"),
            pane(pane_id="%2", window_id="@2", window_index="2", sidebar=True),
            pane(pane_id="%3", window_id="@2", window_index="2"),
        ]
        self.bar.me = self.bar.panes[0]
        self.tmux = patch.object(vtabs, "tmux").start()
        self.addCleanup(patch.stopall)
        self.tmux.return_value.returncode = 0

    def test_split_arrow_and_mouse_sequences_are_buffered(self):
        self.bar.keys(b"\x1b[")
        self.tmux.assert_not_called()
        self.bar.keys(b"B")
        self.assertEqual(self.tmux.call_args.args[:3], ("switch-client", "-t", "$0:@2"))
        self.tmux.reset_mock()
        self.bar.keys(b"\x1b[<0;5;")
        self.tmux.assert_not_called()
        self.bar.keys(b"2M")
        self.assertTrue(self.tmux.called)

    def test_burst_navigation_then_back_uses_destination_pane(self):
        self.bar.keys(b"j\r")
        self.assertEqual(self.tmux.call_args_list[0].args[:3], ("switch-client", "-t", "$0:@2"))
        self.assertEqual(self.tmux.call_args_list[-1].args, ("last-pane", "-t", "%2"))

    def test_navigation_then_delayed_escape_uses_destination(self):
        self.bar.keys(b"j\x1b")
        self.bar.keys(b"", flush=True)
        self.assertEqual(self.tmux.call_args.args, ("last-pane", "-t", "%2"))

    def test_partial_mouse_survives_escape_flush(self):
        self.bar.keys(b"\x1b[<0;5;")
        self.bar.keys(b"", flush=True)
        self.tmux.assert_not_called()
        self.assertEqual(self.bar.pending, b"\x1b[<0;5;")
        self.bar.keys(b"2M")
        self.tmux.assert_called_once_with("last-pane", "-t", "%0")

    def test_mouse_after_navigation_uses_receiving_pane_coordinates(self):
        self.bar.keys(b"j\x1b[<0;5;")
        self.tmux.reset_mock()
        self.bar.keys(b"2M")
        # Row 2 on the receiving sidebar is its own window. Keyboard burst
        # context must not redirect the click/back to window 2's sidebar.
        self.tmux.assert_called_once_with("last-pane", "-t", "%0")

    def test_lone_escape_is_delayed_then_returns_focus(self):
        self.bar.keys(b"\x1b")
        self.tmux.assert_not_called()
        self.bar.keys(b"", flush=True)
        self.tmux.assert_called_once_with("last-pane", "-t", "%0")


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
            "new-session", "-d", "-s", "main", "-x", "120", "-y", "30", "-c", self.tmp, "sleep 600",
        )  # fmt: skip
        self.addCleanup(self.tmux, "kill-server")
        self.tmux("new-window", "-t", "main", "-c", self.tmp, "sleep 600")
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

    def test_hooks_new_window_and_tidy(self):
        self.vtabs("toggle")
        self.tmux("new-window", "-t", "main", "sleep 600")
        self.wait_for(lambda: [p[1] for p in self.panes("main:3")] == ["side", "main"])
        # Closing the last real pane closes the window, not leaving a sidebar.
        main = self.panes("main:3")[1][0]
        self.tmux("kill-pane", "-t", main)
        self.wait_for(lambda: self.tmux("list-windows", "-t", "main", "-F", "#I") == "1\n2")
        # Width is restored after the window resizes.
        self.tmux("resize-window", "-t", "main:1", "-x", "160")
        self.wait_for(lambda: self.panes()[0][3] == "32")

    def test_chooser_empty_agent_title_falls_back_to_window_name(self):
        conf = (SCRIPT.parent / "agent-status.conf").read_text()
        binding = next(line for line in conf.splitlines() if line.startswith("bind-key w "))
        fmt = shlex.split(binding)[-1]
        # Evaluate the actual chooser format in a window row for an agent.
        fmt = fmt.replace("#{?window_format,", "#{?#{==:1,1},").replace("#{pane_current_command}", "claude")
        self.tmux("rename-window", "-t", "main:1", "fallback")
        self.tmux("select-pane", "-t", "main:1", "-T", "")
        self.assertEqual(self.tmux("display", "-p", "-t", "main:1", fmt), "fallback")
        self.tmux("select-pane", "-t", "main:1", "-T", "✳ Full agent title")
        self.assertEqual(self.tmux("display", "-p", "-t", "main:1", fmt), "Full agent title")

    def test_unzoom_adds_sidebar_skipped_while_zoomed(self):
        self.tmux("split-window", "-t", "main:1", "sleep 600")
        self.tmux("resize-pane", "-Z", "-t", "main:1")
        self.vtabs("toggle")
        self.assertFalse(any(p[1] == "side" for p in self.panes()))
        self.assertEqual(self.tmux("display", "-p", "-t", "main:1", "#{window_zoomed_flag}"), "1")
        self.tmux("resize-pane", "-Z", "-t", "main:1")
        self.wait_for(lambda: any(p[1] == "side" for p in self.panes()))
        self.assertEqual(sum(p[1] == "main" for p in self.panes()), 2)

    def test_resizing_window_with_sidebar_does_not_run_ensure(self):
        self.vtabs("toggle")
        self.wait_for(lambda: "▾ main" in self.tmux("capture-pane", "-p", "-t", self.sidebar()))
        # Keep the actual hook condition but replace its Python command with
        # a marker, so this detects needless process launches, not just splits.
        hook = next(line for line in CONF.read_text().splitlines() if line.startswith("set-hook -g after-resize-pane"))
        args = shlex.split(hook)
        args[-1] = args[-1].replace("python3 ~/.tmux/vtabs.py", "touch " + self.tmp + "/ensure-called #")
        result = subprocess.run(
            ["tmux", "-S", self.sock, *args], capture_output=True, text=True,
        )
        self.assertEqual((result.returncode, result.stderr), (0, ""))
        real = next(p[0] for p in self.panes() if p[1] == "main")
        self.tmux("resize-pane", "-t", real, "-x", "70")
        time.sleep(0.3)
        self.assertFalse(Path(self.tmp, "ensure-called").exists())

    def test_sidebar_guard_sees_inactive_panes(self):
        self.vtabs("toggle")
        # The real pane remains active, but P: iterates over every pane.
        self.assertEqual(self.panes()[1][2], "1")
        self.assertEqual(self.tmux("display", "-p", "-t", "main:1", vtabs.HAS_SIDEBAR), "1")

    def test_signal_before_waiter_is_retained(self):
        self.tmux("wait-for", "-S", "early-notification")
        result = subprocess.run(
            ["tmux", "-S", self.sock, "wait-for", "early-notification"],
            timeout=3, capture_output=True,
        )
        self.assertEqual(result.returncode, 0)

    def test_selecting_a_window_wakes_its_sidebar(self):
        # Test the hook without a renderer competing for the same one-shot
        # channel notification.
        self.tmux("set", "-g", "@vtabs-suspended", "1")
        self.tmux("set", "-g", "@vtabs-enabled", "on")
        wid = self.tmux("display", "-p", "-t", "main:2", "#{window_id}")
        waiter = subprocess.Popen(["tmux", "-S", self.sock, "wait-for", f"vtabs-{wid}"])
        self.addCleanup(waiter.kill)
        time.sleep(0.3)
        result = subprocess.run(
            ["tmux", "-S", self.sock, "select-window", "-t", "main:2"],
            capture_output=True,
            text=True,
        )
        self.assertEqual((result.returncode, result.stderr), (0, ""))
        self.assertEqual(waiter.wait(timeout=3), 0)

    def attach(self):
        """Attach a client through a pty; returns a send(bytes) function."""
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

        def send(data):
            os.write(fd, data)
            drain(0.2)

        drain(1.5)
        return send

    def where(self):
        return self.tmux("display", "-p", "#I #{?@vtabs,side,main}")

    def test_keyboard_navigation(self):
        self.tmux("new-window", "-t", "main", "sleep 600")
        self.tmux("select-window", "-t", "main:1")
        self.vtabs("toggle")
        send = self.attach()
        send(b"\x02\t")  # prefix+Tab focuses the sidebar
        self.wait_for(lambda: self.where() == "1 side")
        send(b"\x1b[B")  # down: next window, focus stays in its sidebar
        self.wait_for(lambda: self.where() == "2 side")
        self.wait_for(lambda: "\u258c2" in self.tmux("capture-pane", "-p", "-t", self.sidebar("main:2")))
        send(b"j")
        self.wait_for(lambda: self.where() == "3 side")
        send(b"k")
        self.wait_for(lambda: self.where() == "2 side")
        send(b"\r")  # Enter: back to the window's own pane
        self.wait_for(lambda: self.where() == "2 main")
        send(b"\x02\t")
        self.wait_for(lambda: self.where() == "2 side")
        send(b"3")  # digit: jump to that window
        self.wait_for(lambda: self.where() == "3 side")
        send(b"\x1b")
        self.wait_for(lambda: self.where() == "3 main")
        # prefix+Tab from the sidebar itself hides the sidebars.
        send(b"\x02\t")
        self.wait_for(lambda: self.where() == "3 side")
        send(b"\x02\t")
        self.wait_for(lambda: self.tmux("show", "-gv", "@vtabs-enabled") == "off")
        self.wait_for(lambda: [p[1] for p in self.panes("main:3")] == ["main"])
        self.assertEqual(self.where(), "3 main")
        # ...and prefix+Tab brings them back, focused.
        send(b"\x02\t")
        self.wait_for(lambda: self.where() == "3 side")

    def test_navigation_and_back_in_one_read(self):
        self.vtabs("toggle")
        send = self.attach()
        for suffix in (b"\r", b"\x1b"):
            self.tmux("select-window", "-t", "main:1")
            real = next(p[0] for p in self.panes() if p[1] == "main")
            self.tmux("select-pane", "-t", real)
            send(b"\x02\t")
            self.wait_for(lambda: self.where() == "1 side")
            send(b"j" + suffix)
            self.wait_for(lambda: self.where() == "2 main")

    def test_mouse_click_switches_window_and_leaves_no_focus_behind(self):
        self.tmux("set", "-g", "pane-border-status", "top")
        self.vtabs("toggle")
        send = self.attach()
        # Row 1 is the pane border; sidebar line 2 (terminal row 4) is window 2.
        send(b"\x1b[<0;5;4M\x1b[<0;5;4m")
        self.wait_for(lambda: self.where() == "2 main")
        # Window 1 keeps focus on its own pane, not the clicked sidebar.
        active = self.tmux("display", "-p", "-t", "main:1", "#{?@vtabs,side,main}")
        self.assertEqual(active, "main")


if __name__ == "__main__":
    unittest.main()
