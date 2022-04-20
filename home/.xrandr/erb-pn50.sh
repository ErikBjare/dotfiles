#!/bin/sh

set -e

sleep 0.5

xrandr --output DisplayPort-0 --primary --mode 3840x2160 --refresh 60 --auto
xrandr --output HDMI-A-0 --mode 1920x1080 --refresh 60 --right-of DisplayPort-0 --rotate left --auto
