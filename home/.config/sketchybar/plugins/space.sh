#!/bin/bash
# Redraw the whole space-indicator row in one shot.
#
# Invoked by the `space_driver` item in sketchybarrc, which is the only thing
# subscribed to space/window events. This script repaints ALL ten space items
# via direct `--set`, so the space items themselves never run a script.
#
# ---------------------------------------------------------------------------
# PERF: this is the space-switch hot path
# ---------------------------------------------------------------------------
# Four process spawns total (bash + yabai + jq + sketchybar), regardless of
# space count. The previous version spawned one `yabai -m query` plus three
# `jq` plus a `sketchybar --set` PER SPACE, and all ten space items were
# subscribed to the same six events, so every event redrew every space twice:
# ~65 spawns and ~550ms per space switch, felt directly as lag on top of the
# macOS animation. Keep it to one query, one jq, one batched sketchybar call.
#
# ---------------------------------------------------------------------------
# GOTCHAS (each of these cost real debugging time)
# ---------------------------------------------------------------------------
# 1. icon.highlight SILENTLY OVERRIDES icon.color.
#    `space`-type items ship with a built-in default script,
#    `sketchybar -m --set $NAME icon.highlight=$SELECTED`. When highlight is
#    on, sketchybar draws the icon in icon.highlight_color (BLACK by default)
#    and ignores icon.color entirely. If that builtin ever runs even once the
#    flag latches on the selected space, and `updates=off` then freezes it
#    there: black text on the dark blue active background. We force
#    icon.highlight=off on every redraw below so the row self-heals no matter
#    what latched it.
#
# 2. Icons must be resolved from the space LABEL by index AT DRAW TIME.
#    Moving a space between displays (or un/replugging a monitor) renumbers
#    mission-control indices, so an icon baked statically into each item goes
#    stale. The icons in sketchybarrc are first-paint placeholders only.
#
# 3. Args are read one-per-line into a bash array, never word-split.
#    Space labels contain spaces AND emoji ("1 👨‍💻"), so `sketchybar $args`
#    would shred them. jq emits exactly one argv element per line and the
#    `while read` loop preserves each verbatim.
#
# See sketchybarrc for the two companion gotchas: why the driver cannot be a
# `space` item, and why the `updates=off` pass must run last.

INACTIVE_FG=0xffcccccc
INACTIVE_BG=0xff222222
INACTIVE_BORDER=0xff555555

ACTIVE_FG=0xffffffff
ACTIVE_BG=0xff222299
ACTIVE_BORDER=0xff9999ff

args=()
while IFS= read -r arg; do
  args+=("$arg")
done < <(
  yabai -m query --spaces 2>/dev/null | jq -r \
    --arg ifg "$INACTIVE_FG" --arg ibg "$INACTIVE_BG" --arg ibd "$INACTIVE_BORDER" \
    --arg afg "$ACTIVE_FG"   --arg abg "$ACTIVE_BG"   --arg abd "$ACTIVE_BORDER" '
      (map({key: (.index | tostring), value: .}) | from_entries) as $spaces
      | [ range(1; 11)
          | . as $i
          | ($spaces[$i | tostring]) as $sp
          | select($sp != null)
          | ($sp["has-focus"] == true) as $focused
          | (($sp.windows | length) == 0) as $empty
          | if $empty and ($focused | not) then
              # Hide empty unfocused spaces
              ["--set", "space.\($i)", "drawing=off"]
            else
              ["--set", "space.\($i)", "drawing=on",
               "icon=\($sp.label // ($i | tostring))",
               # Load-bearing: highlight=on would override icon.color with
               # icon.highlight_color (black). See gotcha 1 in the header.
               "icon.highlight=off",
               "icon.color=\(if $focused then $afg else $ifg end)",
               "background.color=\(if $focused then $abg else $ibg end)",
               "background.border_color=\(if $focused then $abd else $ibd end)"]
            end
        ]
      | flatten | .[]
    '
)

[ ${#args[@]} -gt 0 ] && sketchybar "${args[@]}"
exit 0
