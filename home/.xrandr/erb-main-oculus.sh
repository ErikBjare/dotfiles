#!/bin/sh

xrandr --output DVI-1 --off
xrandr --output DisplayPort-0 --off

# Oculus on the HDMI-0
xrandr --output HDMI-0 --auto --primary --rotate left --mode 1080x1920
xrandr --output DVI-0 --auto --same-as HDMI-0
