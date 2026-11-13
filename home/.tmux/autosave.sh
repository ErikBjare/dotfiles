#!/bin/sh
# Periodic tmux-resurrect save, owned by the tmux server itself.
#
# Replaces continuum's save trigger, which is a #() job in status-right and so
# stops silently whenever status-right is reset (theme.conf reload) while
# another tmux server runs (continuum then declines to re-add it), or while the
# status bar is hidden (prefix+b). That gap went unnoticed from 2026-11-04 to a
# crash on 2026-11-12. Continuum still handles restore-on-start.
#
# Started from master.conf with run-shell -b on every load; a per-server
# pidfile keeps reloads from stacking loops. The loop exits with the server.
# The first save waits a full interval, so a fresh server can't overwrite the
# `last` save before continuum restores it.
#
# usage: autosave.sh SOCKET [INTERVAL_SECONDS]

socket=$1
interval=${2:-900}
[ -n "$socket" ] || exit 64
t() { tmux -S "$socket" "$@"; }

save_script="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"
resurrect_dir=$(t show -gqv @resurrect-dir)
resurrect_dir=${resurrect_dir:-$HOME/.tmux/resurrect}

server_pid=$(t display -p '#{pid}') || exit 0
pidfile="${TMPDIR:-/tmp}/tmux-autosave-$(id -u)-$server_pid.pid"
# Atomic create (noclobber); take over only from a dead owner.
if ! (set -C; echo $$ >"$pidfile") 2>/dev/null; then
    kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null && exit 0
    rm -f "$pidfile"
    (set -C; echo $$ >"$pidfile") 2>/dev/null || exit 0
fi
trap 'rm -f "$pidfile"' EXIT

while sleep "$interval" && t has-session 2>/dev/null; do
    # save.sh runs under this server: run-shell exports TMUX for us.
    "$save_script" quiet
    rc=$?
    if [ "$rc" -ne 0 ]; then
        t display-message -d 10000 "tmux autosave: save.sh failed (rc=$rc)"
        continue
    fi
    # Belt and braces: the `last` link must have moved within this round.
    if [ -z "$(find "$resurrect_dir/last" -mmin -2 2>/dev/null)" ]; then
        t display-message -d 10000 "tmux autosave: $resurrect_dir/last not updated"
    fi
done
