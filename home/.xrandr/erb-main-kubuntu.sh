#!/bin/sh

xrandr --output DVI-1 --auto --rotate right
xrandr --output DVI-0 --auto --primary --right-of DVI-1
xrandr --output DisplayPort-0 --auto --right-of DVI-0

