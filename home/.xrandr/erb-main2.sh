#!/bin/sh

#set -e

xrandr --output DP-1 --auto --rotate right
xrandr --output HDMI-0 --auto --primary --mode 3840x2160 --right-of DP-1
xrandr --output DP-2 --auto --right-of HDMI-0

# Disabled displays
xrandr --output DVI-D-0 --off
