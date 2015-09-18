#!/bin/bash

if (hostname=="erb-main-kubuntu"); then
    ./.xrandr-erb-main-kubuntu
    feh --bg-fill "${HOME}/.backgrounds/current_multimonitor"
else
    feh --bg-fill "${HOME}/.backgrounds/current"
fi

zenity --warning --text="Check that systemd user services are behaving" &

# This should be replaced by a systemd service
gnome-keyring-daemon -s &

exec xmonad
