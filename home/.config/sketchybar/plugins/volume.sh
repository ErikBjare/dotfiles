#!/bin/bash

# Get volume and mute status
VOLUME=$(osascript -e 'output volume of (get volume settings)')
MUTED=$(osascript -e 'output muted of (get volume settings)')

if [[ $MUTED == "true" ]]; then
  ICON="󰝟"
else
  case ${VOLUME} in
    100) ICON="󰕾";;
    9[0-9]) ICON="󰕾";;
    [6-8][0-9]) ICON="󰕾";;
    [3-5][0-9]) ICON="󰖀";;
    [1-2][0-9]) ICON="󰕿";;
    *) ICON="󰝟";;
  esac
fi

sketchybar --set $NAME icon="$ICON" label="${VOLUME}%"
