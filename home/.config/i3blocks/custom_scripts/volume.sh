#!/bin/bash

# Handle click events
case $BLOCK_BUTTON in
    1) pactl set-sink-mute @DEFAULT_SINK@ toggle ;; # Left click
    4) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;  # Scroll up
    5) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;  # Scroll down
esac

# Get the volume info
volume_info=$(pactl get-sink-volume @DEFAULT_SINK@)
volume=$(echo "$volume_info" | grep -Po '\d+(?=%)' | head -n 1)
mute_status=$(pactl get-sink-mute @DEFAULT_SINK@)

# Set the icon based on volume level and mute status
if [[ "$mute_status" == "Mute: yes" ]]; then
    icon="🔇"
elif [[ "$volume" -le 33 ]]; then
    icon="🔈"
elif [[ "$volume" -le 66 ]]; then
    icon="🔉"
else
    icon="🔊"
fi

# Output
echo "$icon $volume%"
echo "$icon $volume%"

# Color based on mute status
if [[ "$mute_status" == "Mute: yes" ]]; then
    echo "#888888"
else
    echo "#FFFFFF"
fi
