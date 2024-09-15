#!/bin/bash

idletime=$(xprintidle)
idletime_seconds=$((idletime / 1000))

format_idle_time() {
    local seconds=$1
    local result=""
    
    if ((seconds >= 86400)); then
        result+="$((seconds / 86400))d "
        seconds=$((seconds % 86400))
    fi
    if ((seconds >= 3600)); then
        result+="$((seconds / 3600))h "
        seconds=$((seconds % 3600))
    fi
    if ((seconds >= 60)); then
        result+="$((seconds / 60))m "
        seconds=$((seconds % 60))
    fi
    result+="${seconds}s"
    
    echo "$result"
}

formatted_time=$(format_idle_time $idletime_seconds)

if ((idletime_seconds > 180)); then
    color="#FF5500"
elif ((idletime_seconds > 60)); then
    color="#AAAAAA"
else
    color="#FFFFFF"
fi

echo "💤 $formatted_time"
echo "💤 $formatted_time"
echo "$color"
