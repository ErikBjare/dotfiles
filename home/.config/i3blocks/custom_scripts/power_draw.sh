#!/bin/bash

# Check for battery presence
battery_path=$(find /sys/class/power_supply/BAT* -type d -print -quit 2>/dev/null)

# Check for AC adapter presence
ac_adapter=$(find /sys/class/power_supply/*/ -name "online" -print -quit 2>/dev/null)

# Check if the battery is charging
if [ -n "$battery_path" ] && [ -n "$ac_adapter" ] && [ "$(cat "$ac_adapter" 2>/dev/null)" == "1" ]; then
    echo "🔌"
    echo "#FFFFFF"
# Check if the battery is discharging
elif [ -n "$battery_path" ]; then
    power_now_file="$battery_path/power_now"
    if [ -f "$power_now_file" ]; then
        power_draw=$(awk '{printf "%.1f", $1 / 1000000}' "$power_now_file")
        echo "⚡ ${power_draw}W"
        echo "#FFFF00"
    else
        echo "⚡ N/A"
        echo "#FFFFFF"
    fi
# No battery or AC adapter found
else
    # echo "🔌"
    echo "⚡"
    echo "#FFFFFF"
fi
