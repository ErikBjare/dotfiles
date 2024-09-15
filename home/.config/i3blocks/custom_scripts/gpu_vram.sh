#!/bin/bash

gpu_info=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits)

if [ -n "$gpu_info" ]; then
    used=$(echo $gpu_info | cut -d',' -f1 | tr -d ' ')
    total=$(echo $gpu_info | cut -d',' -f2 | tr -d ' ')
    percentage=$((used * 100 / total))
    
    echo "V🐏 ${percentage}%"
    echo "V🐏 ${percentage}%"
    
    # Color based on VRAM usage percentage
    if [ $percentage -gt 80 ]; then
        echo "#FF0000"
    elif [ $percentage -gt 50 ]; then
        echo "#FFFF00"
    else
        echo "#00FF00"
    fi
else
    echo "V🐏 N/A"
    echo "V🐏 N/A"
    echo "#FFFFFF"
fi
