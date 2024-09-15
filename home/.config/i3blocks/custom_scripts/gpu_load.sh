#!/bin/bash

gpu_load=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)

if [ -n "$gpu_load" ]; then
    echo "🖥️ ${gpu_load}%"
    echo "🖥️ ${gpu_load}%"
    
    # Color based on GPU load
    if [ $gpu_load -gt 80 ]; then
        echo "#FF0000"
    elif [ $gpu_load -gt 50 ]; then
        echo "#FFFF00"
    else
        echo "#00FF00"
    fi
else
    echo "🖥️ N/A"
    echo "🖥️ N/A"
    echo "#FFFFFF"
fi
