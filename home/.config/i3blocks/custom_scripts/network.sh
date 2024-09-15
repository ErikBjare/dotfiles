#!/bin/bash

# Function to get color based on signal strength
get_signal_color() {
    local quality=$1
    if [ $quality -ge 80 ]; then
        echo "#00FF00"  # Strong signal (Green)
    elif [ $quality -ge 60 ]; then
        echo "#FFFF00"  # Good signal (Yellow)
    elif [ $quality -ge 40 ]; then
        echo "#FFA500"  # Fair signal (Orange)
    else
        echo "#FF0000"  # Weak signal (Red)
    fi
}

# Function to get WiFi info
get_wifi_info() {
    local interface="$1"
    local quality=$(grep "$interface" /proc/net/wireless | awk '{print int($3 * 100 / 70)}')
    local essid=$(iwgetid -r)
    if [ -n "$essid" ]; then
        local color=$(get_signal_color $quality)
        echo "📡 ${quality}% @ ${essid}"
        echo "📡 ${quality}% @ ${essid}"
        echo "$color"
    else
        echo "📡 down"
        echo "📡 down"
        echo "#FF0000"
    fi
}

# Function to get Ethernet info
get_ethernet_info() {
    local interface="$1"
    local ip=$(ip addr show dev "$interface" | awk '/inet / {print $2}' | cut -d/ -f1)
    echo "🌐 ${ip}"
    echo "🌐 ${ip}"
    echo "#FFFFFF"
}

# Check for active network interfaces
wifi_interface=$(ip link | awk '/state UP/ && /wl/ {print $2}' | sed 's/://')
ethernet_interface=$(ip link | awk '/state UP/ && /en/ {print $2}' | sed 's/://')

if [ -n "$wifi_interface" ]; then
    get_wifi_info "$wifi_interface"
elif [ -n "$ethernet_interface" ]; then
    get_ethernet_info "$ethernet_interface"
else
    echo "🌐 down"
    echo "🌐 down"
    echo "#FF0000"
fi
