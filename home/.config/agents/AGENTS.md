# Global Preferences

## Git Workflow
- **PR merge strategy**: Always use `--squash` by default. Only use `--rebase` for exceptionally clean/separated commits. Never use `--merge`.
- **Worktrees for new features**: Implement new features in clean git worktrees under `/tmp/worktrees/` and submit PRs. This is the default workflow for ~99% of cases. Exception: autonomous-style runs in Bob's brain repo where state needs to persist and be available for the next session before anyone merges the PR.
- **Pre-commit**: Use `prek` (Rust-based pre-commit) instead of `pre-commit` for installing and running hooks. Config is still `.pre-commit-config.yaml`.
- **No AI tooling attribution**: NEVER add `Co-Authored-By: Claude <noreply@anthropic.com>` or similar AI-tool attribution to commit messages. NEVER add "Generated with Claude Code" or similar to PR descriptions. Exception: Co-authoring as Bob (e.g. `Co-Authored-By: Bob <...>`) is fine when working as Bob, since Bob is a meaningful identity (an "AI person"), not a tool stamp.
