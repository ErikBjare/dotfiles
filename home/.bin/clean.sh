#!/bin/bash
# clean.sh — free disk space by clearing package-manager and tool caches.
# Usage: clean.sh [-y] [-n]
#   -y  non-interactive: answer yes to all prompts
#   -n  dry-run: show what would be removed, delete nothing

set -e  # exit on error

YES=false
DRY=false
while getopts "yn" opt; do
  case $opt in
    y) YES=true ;;
    n) DRY=true ;;
    *) echo "Usage: $(basename "$0") [-y] [-n]"; exit 1 ;;
  esac
done

# bytes -> human readable
human_readable() {
    echo "$1" | awk '{ split("B KB MB GB TB PB", v); s=1; while ($1 > 1024) { $1 /= 1024; s++ } printf "%.1f %s", $1, v[s] }'
}

# free space on / in bytes (df -k for consistent units across macOS/Linux)
free_bytes() {
    echo $(( $(df -k / | tail -1 | awk '{print $4}') * 1024 ))
}

FREE_BEFORE=$(free_bytes)
echo "Free space before clean: $(human_readable "$FREE_BEFORE")"

# measure, remove, and report each path; silently skips paths that don't exist
# (unmatched globs pass through literally and fail the -e test)
clean_path() {
    local path size_kb
    for path in "$@"; do
        [ -e "$path" ] || continue
        size_kb=$(du -sk "$path" 2>/dev/null | cut -f1)
        if $DRY; then
            echo "  would remove $path ($(human_readable $((size_kb * 1024))))"
        else
            rm -rf "$path"
            echo "  removed $path ($(human_readable $((size_kb * 1024))))"
        fi
    done
}

echo
echo "# Package-manager and tool caches"
clean_path ~/.cache/uv ~/Library/Caches/uv
clean_path ~/.cache/pip/http* ~/.cache/pip/wheels ~/.cache/pipenv/http
clean_path ~/.cache/pypoetry/artifacts ~/.cache/pypoetry/*cache
clean_path ~/.cache/yarn
clean_path ~/.npm/_cacache
clean_path ~/.cargo/registry
# NOTE: ~/.cache/huggingface holds downloaded models — clean manually if unwanted

if command -v pnpm > /dev/null; then
    echo "  pruning pnpm store ($(du -sk ~/Library/pnpm/store ~/.local/share/pnpm/store 2>/dev/null | awk '{s+=$1} END {printf "%.1f GB", s/1024/1024}'))"
    $DRY || pnpm store prune > /dev/null 2>&1 || true
fi

if [[ "$(uname)" == "Darwin" ]]; then
    echo
    echo "# macOS caches (~/Library/Caches)"
    clean_path ~/Library/Caches/pip
    clean_path ~/Library/Caches/pypoetry/virtualenvs ~/Library/Caches/pypoetry/artifacts ~/Library/Caches/pypoetry/cache
    clean_path ~/Library/Caches/ms-playwright  # TODO: only clean old versions?
    clean_path ~/Library/Caches/go-build
    clean_path ~/Library/Developer/Xcode/DerivedData
    if command -v brew > /dev/null; then
        echo "  brew cleanup (downloads + old versions)"
        $DRY || brew cleanup --prune=all -s > /dev/null 2>&1 || true
        clean_path ~/Library/Caches/Homebrew
    fi
fi

# truncate runaway service logs (>500MB), keeping the last 10MB
# (truncate in place — the services keep their file handles open)
for logfile in /opt/homebrew/var/log/*.log; do
    [ -f "$logfile" ] || continue
    size_kb=$(du -sk "$logfile" | cut -f1)
    if [ "$size_kb" -gt 512000 ]; then
        echo
        echo "# Truncating oversized log: $logfile ($(human_readable $((size_kb * 1024))))"
        if ! $DRY; then
            tail -c 10m "$logfile" > "$logfile.tail.tmp"
            : > "$logfile"
            cat "$logfile.tail.tmp" > "$logfile"
            rm -f "$logfile.tail.tmp"
        fi
    fi
done

if command -v yay > /dev/null; then
    echo
    echo "# pacman cache (yay)"
    $DRY || yay -Scc --noconfirm
fi

if command -v docker > /dev/null && docker info > /dev/null 2>&1; then
    echo
    echo "# Docker"
    docker system df
    if $YES || { read -p "Prune dangling images + build cache? (y/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]]; }; then
        $DRY || docker image prune -f
        $DRY || docker builder prune -f
    fi
    # volumes are never pruned automatically — check `docker volume ls` yourself
fi

# TM exclusions do NOT apply to local snapshots (they're whole-volume), so
# deletions stay pinned for up to 24h unless we thin the snapshots ourselves
if [[ "$(uname)" == "Darwin" ]]; then
    SNAP_COUNT=$(tmutil listlocalsnapshots / 2>/dev/null | { grep -c com.apple.TimeMachine || true; })
    if [ "$SNAP_COUNT" -gt 0 ]; then
        echo
        echo "# $SNAP_COUNT local Time Machine snapshot(s) may pin the deleted data"
        if $YES || { read -p "Thin local snapshots to release the space? (y/N): " -n 1 -r; echo; [[ $REPLY =~ ^[Yy]$ ]]; }; then
            $DRY || tmutil thinlocalsnapshots / 999999999999 4 > /dev/null || true
        fi
    fi
fi

echo
echo "Not cleaned automatically, check manually if large:"
du -sk ~/Downloads ~/.cache/huggingface 2>/dev/null | awk '{printf "  %s: %.1f GB\n", $2, $1/1024/1024}'

FREE_AFTER=$(free_bytes)
echo
echo "Free space after clean: $(human_readable "$FREE_AFTER")"
FREED=$((FREE_AFTER - FREE_BEFORE))
if $DRY; then
    :
elif [ "$FREED" -le 0 ]; then
    echo "No space was freed"
else
    echo "Freed: $(human_readable "$FREED")"
fi
