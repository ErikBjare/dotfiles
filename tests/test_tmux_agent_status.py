"""Run with python3 -m unittest discover -s tests. No live tmux affected."""

import importlib.util
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

PATH = Path(__file__).resolve().parents[1] / "home/.tmux/agent-status.py"
spec = importlib.util.spec_from_file_location("agent_status", PATH)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ParserTests(unittest.TestCase):
    def test_split_reads_and_both_terminators(self):
        states = []
        parser = module.Parser(states.append)
        data = b"noise\x1b]7501;state=working:app=gptme\x1b\\\x1b]7501;state=blocked:kind=permission\x07"
        for byte in data:
            parser.feed(bytes([byte]))
        self.assertEqual(states, ["working", "blocked"])

    def test_ignore_children_queries_and_invalid(self):
        states = []
        parser = module.Parser(states.append)
        parser.feed(
            b"\x1b]7501;?\x07\x1b]7501;state=wat\x07\x1b]7501;state=blocked:id=child\x07"
        )
        parser.feed(b"\x1b]7501;state=done:msg=YQ==\x07")
        self.assertEqual(states, ["done"])

    def test_bounded_and_recovers(self):
        states = []
        parser = module.Parser(states.append)
        parser.feed(b"\x1b]" + b"x" * 10000)
        parser.feed(b"\x1b]7501;state=idle\x07")
        self.assertEqual(states, ["idle"])

    def test_shell_prompt_clears_crashed_agent(self):
        states = []
        parser = module.Parser(states.append)
        parser.feed(b"\x1b]7501;state=working\x07\x1b]133;A\x1b\\")
        self.assertEqual(states, ["working", "clear"])


class InstallTests(unittest.TestCase):
    def test_existing_pipes_are_not_toggled(self):
        calls = []

        def run(*args):
            calls.append(args)
            return SimpleNamespace(returncode=0, stdout="%1:1\n%2:0\n", stderr="")

        with patch.object(module, "tmux", run):
            module.install()
        self.assertEqual(len(calls), 2)
        self.assertEqual(
            calls[1][:5], ("if-shell", "-F", "-t", "%2", "#{==:#{pane_pipe},0}")
        )
        self.assertIn("--watch %%2", calls[1][-1])
        # Shell-escaped by tmux, never interpolated inside shell quotes.
        self.assertIn(" #{q:socket_path}'", calls[1][-1])
        self.assertNotIn('"#{socket_path}"', calls[1][-1])

    def test_conf_hooks_shell_escape_socket(self):
        conf = (PATH.parent / "agent-status.conf").read_text()
        installs = [line for line in conf.splitlines() if "--install" in line]
        self.assertEqual(len(installs), 4)
        for line in installs:
            self.assertIn("--install #{q:socket_path}", line)


class ReporterTests(unittest.TestCase):
    def run_reports(self, states):
        calls = []
        with patch.object(module, "tmux", lambda *args: calls.append(args)):
            report = module.reporter("%3")
            for state in states:
                report(state)
        return [c for c in calls if c[0] == "set-option"]

    def test_repeat_report_reapplied_after_manual_clear(self):
        # README: `tmux set-option -pu -t %PANE @agent-state` happens between
        # these reports, outside the watcher; the repeat must not be dropped.
        sets = self.run_reports(["working", "working"])
        self.assertEqual(
            sets, [("set-option", "-p", "-t", "%3", "@agent-state", "working")] * 2
        )

    def test_repeated_prompt_clears_are_collapsed(self):
        sets = self.run_reports(["clear", "clear", "done", "clear", "clear"])
        unset = ("set-option", "-pu", "-t", "%3", "@agent-state")
        done = ("set-option", "-p", "-t", "%3", "@agent-state", "done")
        self.assertEqual(sets, [unset, done, unset])


if __name__ == "__main__":
    unittest.main()
