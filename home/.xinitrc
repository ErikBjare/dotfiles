#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    xrandr --output HDMI-0 --auto
    xrandr --output DVI-1 --auto --primary --right-of HDMI-0
    xrandr --output DisplayPort-0 --right-of DVI-1
fi

# "bg"
feh --bg-fill "${HOME}/.xmonad/bg.png"
redshift -l 55:13 -t 6500:3500 &
rescuetime &
[[ "$(proc rescuetime | wc -l)" = "2" ]] || zenity --warning --text="rescuetime could not be started"
gnome-keyring-daemon -s &


exec xmonad
