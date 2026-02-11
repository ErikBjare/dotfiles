#!/bin/bash

# Colors for inactive workspaces
INACTIVE_COLOR_FG=0xffcccccc
INACTIVE_COLOR_BG=0xff222222
INACTIVE_COLOR_BORDER=0xff555555

# Colors for active workspace
ACTIVE_COLOR_FG=0xffffffff
ACTIVE_COLOR_BG=0xff222299
ACTIVE_COLOR_BORDER=0xff9999ff

update_space() {
  local space_id=$1
  local target=$2

  # Get space info and window count
  SPACE_INFO=$(yabai -m query --spaces --space "$space_id" 2>/dev/null)
  # echo "Space info: $SPACE_INFO" >> /tmp/sketchybar.log
  if [ -n "$SPACE_INFO" ]; then
    FOCUSED=$(echo "$SPACE_INFO" | jq -r '.["has-focus"]')
    # echo "Space $space_id focus: $FOCUSED (event: $SENDER)" >> /tmp/sketchybar.log
    WINDOWS=$(echo "$SPACE_INFO" | jq -r '.windows | map(select(. != 2385)) | length')

    if [ "$WINDOWS" -eq 0 ] && [ "$FOCUSED" != "true" ]; then
      # Hide empty unfocused spaces
      sketchybar --set $target drawing=off
    else
      # Show space and set appropriate colors
      sketchybar --set $target drawing=on

      if [ "$FOCUSED" = "true" ]; then
        # Active workspace - light blue theme
        sketchybar --set $target \
          icon.color=$ACTIVE_COLOR_FG \
          background.color=$ACTIVE_COLOR_BG \
          background.border_color=$ACTIVE_COLOR_BORDER
      else
        # Inactive workspace with windows
        sketchybar --set $target \
          icon.color=$INACTIVE_COLOR_FG \
          background.color=$INACTIVE_COLOR_BG \
          background.border_color=$INACTIVE_COLOR_BORDER
      fi
    fi
  fi
}

# echo "Name: $NAME, Sender: $SENDER" >> /tmp/sketchybar.log

# Force update all spaces on space 1
if [ "$NAME" = "space.1" ]; then
  for i in {1..10}; do
    echo "Updating space $i" >> /tmp/sketchybar.log
    update_space $i space.$i
  done
else
  # Handle individual space updates
  SPACE_ID=$(echo "$NAME" | cut -d '.' -f 2)
  # echo "Space ID: $SPACE_ID" >> /tmp/sketchybar.log
  if [ -n "$SPACE_ID" ]; then
    update_space "$SPACE_ID" "$NAME"
  fi
fi
