#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    xrandr --output HDMI-0 --auto --primary
    xrandr --output DisplayPort-0 --left-of HDMI-0
    xrandr --output DVI-1 --right-of HDMI-0
fi

# "bg"
feh --bg-fill "${HOME}/.xmonad/bg.png"
redshift -l 55:13 -t 6500:3500 &
dropbox start &
gnome-keyring-daemon -s &

exec xmonad
