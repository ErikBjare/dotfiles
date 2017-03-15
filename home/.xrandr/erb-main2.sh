#!/bin/sh

xrandr --output DP-1 --auto
xrandr --output HDMI-0 --auto --primary --mode 3840x2160 --refresh 60 --right-of DP-1
xrandr --output DP-4 --auto --right-of HDMI-0

# Disabled displays
xrandr --output DVI-D-0 --off
