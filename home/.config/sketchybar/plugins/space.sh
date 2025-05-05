#!/bin/bash

update_space() {
  local space_id=$1
  local target=$2
  
  # Get space info and window count
  SPACE_INFO=$(yabai -m query --spaces --space "$space_id" 2>/dev/null)
  if [ -n "$SPACE_INFO" ]; then
    FOCUSED=$(echo "$SPACE_INFO" | jq -r '.["has-focus"]')
    # Count windows excluding the background app (2385)
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
          background.color=0xff222299 \
          icon.color=0xffffffff \
          background.border_color=0xff9999ff
      else
        # Inactive workspace with windows
        sketchybar --set $target \
          background.color=0xff111111 \
          icon.color=0xffffffff \
          background.border_color=0xff222222
      fi
    fi
  fi
}

# Force update all spaces initially
if [ "$NAME" = "space.1" ]; then
  for i in {1..10}; do
    update_space $i space.$i
  done
fi

# Handle individual space updates
SPACE_ID=$(echo "$INFO" | jq -r '."space-id"' 2>/dev/null)
if [ -n "$SPACE_ID" ]; then
  update_space "$SPACE_ID" "$NAME"
fi
