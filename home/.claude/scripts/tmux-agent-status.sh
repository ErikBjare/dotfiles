#!/bin/sh
# Claude Code hook -> tmux agent badge (see ~/.tmux/agent-status.conf).
#
# gptme reports state as OSC 7501 on its terminal, which agent-status.py reads
# through pipe-pane. Claude Code runs hooks without a controlling terminal
# (/dev/tty is unavailable), so an OSC write can't reach the pane. Instead set
# the same @agent-state pane option the bridge sets. No-op outside tmux.
#
# usage (from settings.json hooks): tmux-agent-status.sh STATE
#   STATE: idle | working | done | blocked | error | clear

cat >/dev/null 2>&1   # drain the hook's JSON input
[ -n "$TMUX" ] && [ -n "$TMUX_PANE" ] || exit 0

case "$1" in
    clear) tmux set-option -pu -t "$TMUX_PANE" @agent-state ;;
    idle | working | done | blocked | error)
        tmux set-option -p -t "$TMUX_PANE" @agent-state "$1" ;;
    *) exit 0 ;;
esac 2>/dev/null
tmux refresh-client -S 2>/dev/null
exit 0
