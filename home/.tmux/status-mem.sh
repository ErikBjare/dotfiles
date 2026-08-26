#!/bin/sh
# % memory available + best-per-OS pressure signal for the tmux status bar.
# Linux: MemAvailable/MemTotal + PSI (/proc/pressure/memory, some avg60),
#        PSI shown only when elevated (>=1% yellow, >=10% red).
# macOS: free% from memory_pressure + kern.memorystatus_vm_pressure_level,
#        level shown only when warning (2) or critical (4).
if [ -r /proc/meminfo ]; then
    avail=$(awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} END{if(t)printf "%d", a*100/t}' /proc/meminfo)
    psi=$(awk -F'avg60=' '/^some/{split($2,a," "); printf "%d", a[1]+0.5}' /proc/pressure/memory 2>/dev/null)
    out="${avail:-?}%"
    if [ "${psi:-0}" -ge 10 ]; then
        out="#[fg=colour221,bold]${out} psi:${psi}%"
    elif [ "${psi:-0}" -ge 1 ]; then
        out="#[fg=colour229]${out} psi:${psi}%"
    fi
else
    avail=$(memory_pressure -Q 2>/dev/null | awk -F': *' '/free percentage/{gsub(/[% ]/,"",$2); print $2}')
    level=$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null)
    out="${avail:-?}%"
    case "$level" in
    4) out="#[fg=colour221,bold]${out} crit" ;;
    2) out="#[fg=colour229]${out} warn" ;;
    esac
fi
printf '%s' "$out"
