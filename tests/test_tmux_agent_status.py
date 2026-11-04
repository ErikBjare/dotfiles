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
        self.assertIn("#{socket_path}", calls[1][-1])


if __name__ == "__main__":
    unittest.main()
