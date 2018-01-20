#!/bin/bash

FOLDER="$HOME/Public/Screenshots"
FILE="$FOLDER/$(date --iso-8601=seconds).png"

if [ "$1" == "--help" ]; then
    echo "Arguments:"
    echo "  --region"
    echo "  --fullscreen"
    exit 0
elif [ "$1" == "--region" ]; then
    echo "Doing a region shot!"
    escrotum --select $FILE
    notify-send --expire-time=3000 --app-name="Screenshot" "Captured region"
elif [ "$1" == "--fullscreen" ]; then
    echo "Doing a fullscreen shot!"
    escrotum $FILE
    notify-send --expire-time=3000 --app-name="Screenshot" "Captured fullscreen"
else
    echo "Needs a command line argument, see --help for info."
    exit 1
fi
xclip -sel clip -t image/png $FILE
