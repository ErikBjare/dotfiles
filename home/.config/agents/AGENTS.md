# Global Agent Instructions

Shared across agent runtimes:
- `~/.claude/CLAUDE.md` → an AGENTS.md like this one (Claude Code)
- Other runtimes (Codex, gptme) pick up `AGENTS.md` from this location

This is the short, public-safe version and the default on all machines.
Nothing sensitive belongs in this file. A fuller private version (memory
indexes, machine/infra context) is imported below on machines that have it;
elsewhere the import resolves to nothing.

@~/Programming/erbot/AGENTS.md

Keep instructions here generic and runtime-agnostic. Project-specific
instructions go in each repo's own `CLAUDE.md`/`AGENTS.md`.

# Global Preferences

## Git Workflow
- **PR merge strategy**: Use `--squash` for typical PRs (single logical change, review fixups get folded in). Use `--rebase` when the branch has multiple distinct commits worth preserving individually. Never use `--merge`.
- **Worktrees for new features**: Implement new features in clean git worktrees under `/tmp/worktrees/`. If there's a remote, submit PRs; if local-only, rebase onto the target branch directly.
- **Pre-commit**: Use `prek` (Rust-based pre-commit) instead of `pre-commit` for installing and running hooks. Config is still `.pre-commit-config.yaml`.
- **No AI tooling attribution**: Never add `Co-Authored-By: Claude` or similar AI-tool attribution to commit messages, nor "Generated with ..." to PR descriptions.

## CI Workflow
- **Always verify CI passes**: After pushing fixes, wait for CI to finish (`gh pr checks <num> --watch`). If checks fail, read the logs, fix, push, and loop until all checks are green.
- **Run tests locally first**: Run the relevant test suite locally before pushing to catch issues early.
- **Use subagents for small CI fixes** (typos, missing mocks) to keep the main context clean.
- **Trigger a review bot before merge** (check which reviewer the repo actually uses), read the review, and address findings before merging. Reply to and resolve review comment threads after fixing feedback.
