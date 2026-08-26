#!/bin/sh
# 1/5/15-min load averages for the tmux status bar.
# Colors the output when 1-min load is high relative to core count:
# >=50% of cores -> yellow, >=100% -> red-ish (palette colour221), bold.
ncpu=$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 1)
# Normalize "load averages: 1.93 2.07 2.20" (macOS) / "load average: 0.52, 0.58, 0.59" (Linux)
set -- $(uptime | sed 's/.*load averages*: *//; s/,/ /g')
warn=$(awk -v l="$1" -v n="$ncpu" 'BEGIN{print (l>=n)?2:(l>=n/2)?1:0}')
case $warn in
2) color='#[fg=colour221,bold]' ;;
1) color='#[fg=colour229]' ;;
*) color='' ;;
esac
printf '%s%s %s %s' "$color" "$1" "$2" "$3"
