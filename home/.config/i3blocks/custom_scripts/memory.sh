#!/bin/bash

mem_info=$(free -b | awk '/Mem:/ {print $2,$3}')
total_mem=$(echo $mem_info | cut -d' ' -f1)
used_mem=$(echo $mem_info | cut -d' ' -f2)

mem_percentage=$(awk "BEGIN {printf \"%.0f\", $used_mem / $total_mem * 100}")

echo "🐏 ${mem_percentage}%"
echo "🐏 ${mem_percentage}%"

# Color calculation
if [ $mem_percentage -ge 85 ]; then
    echo "#FFFF00"
elif [ $mem_percentage -le 50 ]; then
    echo "#00FF00"
else
    r=$((255 * (mem_percentage - 50) / 35))
    g=255
    printf "#%02X%02X00\n" $r $g
fi
