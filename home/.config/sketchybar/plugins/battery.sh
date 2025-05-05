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

sketchybar --set $NAME icon="$ICON" label="${PERCENTAGE}%"
