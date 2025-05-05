#!/bin/bash

# Get the current window info
WINDOW_INFO=$(yabai -m query --windows --window 2>/dev/null)

if [ -n "$WINDOW_INFO" ]; then
  # Get both app name and window title
  APP=$(echo "$WINDOW_INFO" | jq -r '.app')
  TITLE=$(echo "$WINDOW_INFO" | jq -r '.title')

  # Use app name if title is empty
  if [ "$TITLE" = "" ] || [ "$TITLE" = "null" ]; then
    LABEL="$APP"
  else
    # If title is too long, truncate it
    if [ ${#TITLE} -gt 50 ]; then
      TITLE=$(echo "$TITLE" | cut -c 1-47)"..."
    fi
    LABEL="$TITLE"
  fi
else
  LABEL="Desktop"
fi

sketchybar --set $NAME label="$LABEL"
