#!/bin/sh

set -e

#xrandr --output HDMI-0 --off
#xrandr --output DP-1 --off

sleep 0.5

# ASUS
xrandr --output HDMI-0 --primary --mode 3840x2160 --refresh 60 --pos 0x0 --panning 0x0

# SwedTV
xrandr --output DP-0 --mode 3840x2160 --refresh 60 --right-of HDMI-0

# LG
#xrandr --output HDMI-0 --off
#xrandr --output HDMI-0 --mode 3840x2160 --refresh 60 --right-of DP-0
#xrandr --output DVI-D-0 --mode 800x480 --right-of HDMI-0 #--panning 0x0
#xrandr --output DP-2 --auto --right-of HDMI-0

# Disabled displays
#xrandr --output DP-0 --off
