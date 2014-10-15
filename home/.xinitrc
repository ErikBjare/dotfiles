#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    ./.xrandr-erb-main-kubuntu
fi

# "bg"
feh --bg-fill "${HOME}/.xmonad/bg.png"
redshift -l 55:13 -t 6500:3500 &
dropbox start &
zenity --warning --text="Remember to start RescueTime (and maybe Dropbox, check if it is running)" &
gnome-keyring-daemon -s &


exec xmonad
