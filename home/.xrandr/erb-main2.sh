#!/bin/sh

set -e


xrandr --output DP-3 --off
xrandr --output HDMI-0 --off


xrandr --output HDMI-0 --primary --mode 3840x2160 --right-of DP-3 #--panning 0x0
xrandr --output DP-3 --auto --left-of HDMI-0 --rotate right #--panning 0x0
#xrandr --output DP-2 --auto --right-of HDMI-0

# Disabled displays
xrandr --output DP-0 --off
