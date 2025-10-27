#!/bin/bash

if [[ $(hostname) == "erb-main2-arch" || $(hostname) == "erb-laptop2-arch" ]]; then
    # Fix for this maybe? https://unix.stackexchange.com/a/295652/45373
    source /etc/X11/xinit/xinitrc.d/50-systemd-user.sh

    # see: https://wiki.archlinux.org/index.php/GNOME/Keyring#xinitrc_method
    eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK
fi

# source profiles
~/.profile
~/.xprofile

# Choose WM/DE based on environment variable
# Usage: WM=plasma startx  or  WM=i3 startx
case "${WM:-i3}" in
    plasma)
        exec startplasma-x11
        ;;
    i3)
        exec i3 -V # >> ~/.cache/i3-$(date +'%F-%k-%M-%S').log 2>&1
        ;;
esac
