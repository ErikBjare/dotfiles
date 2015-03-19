#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    ./.xrandr-erb-main-kubuntu
    feh --bg-fill "${HOME}/.backgrounds/current_multimonitor"
else
    feh --bg-fill "${HOME}/.backgrounds/current"
fi

# "bg"

# Background apps
redshift -l 55:13 -t 7000:2500 &
dropbox start &
rescuetime &
zenity --warning --text="Remember to check that RescueTime and Dropbox is running" &
gnome-keyring-daemon -s &

exec xmonad
