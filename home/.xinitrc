#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    xrandr --output HDMI-0 --auto
    xrandr --output DVI-1 --auto --primary --right-of HDMI-0
    xrandr --output DisplayPort-0 --right-of DVI-1
fi

# "bg"
feh --bg-fill "${HOME}/.xmonad/bg.png"
redshift -l 55:13 -t 6500:3500 &
dropbox start &
zenity --warning --text="Remember to start RescueTime (and maybe Dropbox, check if it is running)" &
gnome-keyring-daemon -s &


exec xmonad
