#!/bin/bash

# Get disk usage for root partition
disk_info=$(df -h / | awk '/\/$/ {print $4}')

echo "💾 ${disk_info}"
echo "💾 ${disk_info}"

# Color is always white for disk usage
echo "#FFFFFF"
