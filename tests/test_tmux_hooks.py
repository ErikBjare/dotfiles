"""Claude Code -> tmux agent-state hook and the tmux autosave loop.

Run with python3 -m unittest discover -s tests. Each test starts its own tmux
server on a private socket; no live tmux or resurrect save is touched.
"""

import os
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HOOK = ROOT / "home/.claude/scripts/tmux-agent-status.sh"
AUTOSAVE = ROOT / "home/.tmux/autosave.sh"


@unittest.skipUnless(shutil.which("tmux"), "tmux not installed")
class TmuxServerTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.sock = os.path.join(self.tmp, "s")
        self.tmux("-f", "/dev/null", "new-session", "-d", "-s", "t", "sh")
        self.addCleanup(self.tmux, "kill-server")
        self.pane = self.tmux("display", "-p", "#{pane_id}").strip()

    def tmux(self, *args):
        return subprocess.run(
            ["tmux", "-S", self.sock, *args], capture_output=True, text=True
        ).stdout

    def state(self):
        return self.tmux("display", "-p", "-t", self.pane, "#{@agent-state}").strip()


class HookTests(TmuxServerTest):
    def run_hook(self, *args, tmux_env=True):
        env = {k: v for k, v in os.environ.items() if k not in ("TMUX", "TMUX_PANE")}
        if tmux_env:
            # The TMUX env var's first field is the socket path.
            env.update(TMUX=f"{self.sock},0,0", TMUX_PANE=self.pane)
        return subprocess.run(
            [str(HOOK), *args], input="{}", capture_output=True, text=True, env=env
        )

    def test_states_and_clear(self):
        for state in ["idle", "working", "blocked", "done", "error"]:
            result = self.run_hook(state)
            self.assertEqual((result.returncode, result.stdout), (0, ""))
            self.assertEqual(self.state(), state)
        self.run_hook("clear")
        self.assertEqual(self.state(), "")

    def test_unknown_state_is_ignored(self):
        self.run_hook("working")
        self.assertEqual(self.run_hook("bogus").returncode, 0)
        self.assertEqual(self.state(), "working")

    def test_noop_outside_tmux(self):
        result = self.run_hook("working", tmux_env=False)
        self.assertEqual((result.returncode, result.stdout), (0, ""))
        self.assertEqual(self.state(), "")


class AutosaveTests(TmuxServerTest):
    def test_saves_once_per_server_and_exits_with_it(self):
        save_dir = os.path.join(self.tmp, "resurrect")
        os.makedirs(save_dir)
        # Stand-in for resurrect's save.sh: same `last` link contract.
        fake_home = os.path.join(self.tmp, "home")
        script = Path(fake_home, ".tmux/plugins/tmux-resurrect/scripts/save.sh")
        script.parent.mkdir(parents=True)
        script.write_text(
            f'#!/bin/sh\necho x >> "{save_dir}/count"\n'
            f'ln -fs count "{save_dir}/last"\n'
        )
        script.chmod(0o755)
        self.tmux("set", "-g", "@resurrect-dir", save_dir)
        env = dict(os.environ, HOME=fake_home, TMPDIR=self.tmp)
        procs = [
            subprocess.Popen(["sh", str(AUTOSAVE), self.sock, "1"], env=env)
            for _ in range(2)
        ]
        time.sleep(2.5)
        # The duplicate loop exits at once; the owner keeps going.
        self.assertEqual(sum(p.poll() is None for p in procs), 1)
        saves = Path(save_dir, "count").read_text().count("x")
        self.assertGreaterEqual(saves, 1)
        self.assertLessEqual(saves, 3)
        self.tmux("kill-server")
        for p in procs:
            p.wait(timeout=5)
        self.assertEqual(list(Path(self.tmp).glob("tmux-autosave-*")), [])


if __name__ == "__main__":
    unittest.main()
