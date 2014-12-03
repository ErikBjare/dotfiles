#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    ./.xrandr-erb-main-kubuntu
fi

# "bg"
feh --bg-fill "${HOME}/.xmonad/bg.png"

# Background apps
redshift -l 55:13 -t 6500:3500 &
dropbox start &
rescuetime &
zenity --warning --text="Remember to check that RescueTime and Dropbox is running" &
gnome-keyring-daemon -s &

exec xmonad
