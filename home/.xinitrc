#!/bin/bash

if [[ $(hostname) == "erb-main2-arch" ]]; then
    # Fix for this maybe? https://unix.stackexchange.com/a/295652/45373
    source /etc/X11/xinit/xinitrc.d/50-systemd-user.sh

    # see: https://wiki.archlinux.org/index.php/GNOME/Keyring#xinitrc_method
    eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)
    export SSH_AUTH_SOCK
fi

# source profiles
~/.profile
~/.xprofile

#exec startxfce4
exec i3 -V # >> ~/.cache/i3-$(date +'%F-%k-%M-%S').log 2>&1
