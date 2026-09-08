#!/bin/bash

# Get battery info
BATT_INFO="$(pmset -g batt)"
PERCENTAGE=$(echo "$BATT_INFO" | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(echo "$BATT_INFO" | grep -Eo "AC Power|charged" >/dev/null && echo "true" || echo "false")

# Exit if no battery found (e.g. on desktop Macs)
if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

# Set the icon based on battery percentage
if [ "$CHARGING" = "true" ]; then
  ICON="󰂄"
else
  case ${PERCENTAGE} in
    100|9[0-9]) ICON="󰁹";;
    [6-8][0-9]) ICON="󰂁";;
    [3-5][0-9]) ICON="󰁾";;
    [1-2][0-9]) ICON="󰁻";;
    *) ICON="󰁺";;
  esac
fi

# Set color based on battery percentage and charging status
if [ "$CHARGING" = "true" ]; then
  if [ "$PERCENTAGE" -eq 100 ]; then
    COLOR="0xff00aa00"  # Green for fully charged and charging
  else
    COLOR="0xffffffff"  # White for charging
  fi
elif [ "$PERCENTAGE" -lt 5 ]; then
  COLOR="0xffff0000"  # Red for critically low battery (<5%)
elif [ "$PERCENTAGE" -lt 15 ]; then
  COLOR="0xffffff00"  # Yellow for low battery (<15%)
else
  COLOR="0xffffffff"  # White for normal battery
fi

sketchybar --set $NAME icon="$ICON" label="${PERCENTAGE}%" icon.color="$COLOR" label.color="$COLOR"
