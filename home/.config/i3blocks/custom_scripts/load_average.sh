#!/bin/bash

# Get the load averages
read one five fifteen rest < /proc/loadavg

# Function to get color based on load
get_load_color() {
    local load=$1
    local cores=$(nproc)
    local threshold=$(echo "$cores * 0.7" | bc)
    
    if (( $(echo "$load > $threshold" | bc -l) )); then
        echo "#FF0000"  # High load (Red)
    elif (( $(echo "$load > $cores * 0.5" | bc -l) )); then
        echo "#FFFF00"  # Medium load (Yellow)
    else
        echo "#00FF00"  # Low load (Green)
    fi
}

# Get color based on 1-minute load average
color=$(get_load_color $one)

# Output for i3blocks
echo "⚖️ $one"
echo "⚖️ $one"
echo "$color"
