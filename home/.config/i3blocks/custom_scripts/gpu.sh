#!/bin/bash

# Get GPU info with a single call to nvidia-smi
gpu_info=$(nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits)

if [ -n "$gpu_info" ]; then
    # Parse the output
    IFS=',' read -r gpu_load mem_used mem_total <<< "$gpu_info"

    # Remove leading/trailing whitespace
    gpu_load=$(echo $gpu_load | xargs)
    mem_used=$(echo $mem_used | xargs)
    mem_total=$(echo $mem_total | xargs)

    # Calculate VRAM usage percentage
    vram_usage=$((mem_used * 100 / mem_total))

    # Determine color based on the higher of GPU load and VRAM usage
    if [ $gpu_load -gt $vram_usage ]; then
        percentage=$gpu_load
    else
        percentage=$vram_usage
    fi

    if [ $percentage -gt 80 ]; then
        color="#FF0000"
    elif [ $percentage -gt 50 ]; then
        color="#FFFF00"
    else
        color="#00FF00"
    fi

    # pad with spaces
    gpu_load=$(printf "%2s" $gpu_load)
    vram_usage=$(printf "%2s" $vram_usage)

    # Output
    echo "🖥️ ${gpu_load}% 🐏 ${vram_usage}%"
    echo "🖥️ ${gpu_load}% 🐏 ${vram_usage}%"
    echo $color
else
    echo "🖥️ N/A | V🐏 N/A"
    echo "🖥️ N/A | V🐏 N/A"
    echo "#FFFFFF"
fi
