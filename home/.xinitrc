#!/bin/bash

~/.profile
~/.xprofile

#exec startxfce4
exec i3 -V # >> ~/.cache/i3-$(date +'%F-%k-%M-%S').log 2>&1
