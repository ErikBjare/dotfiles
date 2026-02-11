#!/bin/bash

# Get the CPU Package temperature
temp=$(sensors | awk '/^CPU Package:/ {print $3; exit}' | tr -d '+°C')

if [ -n "$temp" ]; then
    temp=${temp%.*}  # Remove decimal part
    echo "🌡️ ${temp}°C"
    echo "🌡️ ${temp}°C"

    # Color based on temperature
    if [ $temp -gt 80 ]; then
        echo "#FF0000"
    elif [ $temp -gt 60 ]; then
        echo "#FFFF00"
    else
        echo "#00FF00"
    fi
else
    echo "🌡️ N/A"
    echo "🌡️ N/A"
    echo "#FFFFFF"
fi
