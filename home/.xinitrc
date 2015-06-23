#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    ./.xrandr-erb-main-kubuntu
    feh --bg-fill "${HOME}/.backgrounds/current_multimonitor"
else
    feh --bg-fill "${HOME}/.backgrounds/current"
fi

# Background apps
# It might be unreliable to start them before xmonad & co is loaded, but works for some things at least
# A notable example that used to exist here was rescuetime (didn't show up in tray  but ran in background, sometimes)
redshift -l 55:13 -t 7000:2500 &
dropbox start &
zenity --warning --text="Remember to check that RescueTime and Dropbox is running" &
gnome-keyring-daemon -s &

exec xmonad
