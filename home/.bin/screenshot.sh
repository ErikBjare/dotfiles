#!/bin/bash
# Cross-platform screenshot script: escrotum on Linux (i3), screencapture on macOS.
# Both modes save to the screenshots folder AND put the image in the clipboard.

MACOS=false
[ "$(uname)" = "Darwin" ] && MACOS=true

SHUTTER_SOUND="/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif"

msg() {
    echo "$1"
    if $MACOS; then
        [ -f "$SHUTTER_SOUND" ] && afplay "$SHUTTER_SOUND" &
        # terminal-notifier over osascript: notifications from background
        # processes (skhd) get silently suppressed with plain osascript
        if hash terminal-notifier 2>/dev/null; then
            terminal-notifier -title "Screenshot" -message "$1" -contentImage "$FILE" >/dev/null
        else
            osascript -e "display notification \"$1\" with title \"Screenshot\""
        fi
    else
        notify-send --expire-time=3000 --app-name="Screenshot" "$1"
    fi
}

if $MACOS; then
    HOSTNAME=$(scutil --get LocalHostName)
    DATE=$(date +%Y-%m-%dT%H:%M:%S%z)
else
    HOSTNAME=$(hostnamectl --static)
    DATE=$(date --iso-8601=seconds)
fi
FOLDER="$HOME/annex/Logs/Screenshots/$HOSTNAME"
FILE="$FOLDER/$DATE.png"
mkdir -p "$FOLDER"

if ! $MACOS; then
    MSG_ERROR_ESCROTUM="escrotum not installed, please install it"
    hash escrotum || (msg "$MSG_ERROR_ESCROTUM" && exit 1)
fi

if [ "$1" == "--help" ]; then
    echo "Arguments:"
    echo "  --region"
    echo "  --fullscreen"
    exit 0
elif [ "$1" == "--region" ]; then
    echo "Doing a region shot!"
    if $MACOS; then
        # -i: interactive selection (space toggles window mode); exits silently if cancelled
        screencapture -i "$FILE"
        [ -s "$FILE" ] || exit 1
    else
        escrotum --select "$FILE" || (echo 'escrotum failed' && exit 1)
    fi
    msg "Captured region"
elif [ "$1" == "--fullscreen" ]; then
    if $MACOS; then
        screencapture "$FILE" || (echo 'screencapture failed' && exit 1)
    else
        escrotum "$FILE" || (echo 'escrotum failed' && exit 1)
    fi
    msg "Captured fullscreen"
else
    echo "Needs a command line argument, see --help for info."
    exit 1
fi

echo 'Putting in clipboard'
if $MACOS; then
    osascript -e "set the clipboard to (read (POSIX file \"$FILE\") as «class PNGf»)"
else
    xclip -sel clip -t image/png "$FILE"
fi
