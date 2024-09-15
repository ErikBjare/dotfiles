#!/bin/bash

# Find the first available backlight device
backlight_dir=$(find /sys/class/backlight -type d | head -n 1)

if [ -n "$backlight_dir" ] && [ -f "$backlight_dir/max_brightness" ] && [ -f "$backlight_dir/brightness" ]; then
    max_brightness=$(cat "$backlight_dir/max_brightness")
    current_brightness=$(cat "$backlight_dir/brightness")
    if [ "$max_brightness" -ne 0 ]; then
        brightness_percent=$((current_brightness * 100 / max_brightness))

        echo "🌞 ${brightness_percent}%"
        echo "🌞 ${brightness_percent}%"

        # Color calculation
        r=$((136 + (255 - 136) * brightness_percent / 100))
        g=$((51 + (255 - 51) * brightness_percent / 100))
        b=0
        printf "#%02X%02X%02X\n" $r $g $b
    else
        echo "🌞 N/A"
        echo "🌞 N/A"
        echo "#FFFFFF"
    fi
else
    echo "🌞 N/A"
    echo "🌞 N/A"
    echo "#FFFFFF"
fi
