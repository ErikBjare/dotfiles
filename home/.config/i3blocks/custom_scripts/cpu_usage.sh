#!/bin/bash

# Read the first line of /proc/stat
read cpu user nice system idle iowait irq softirq steal guest guest_nice <<< "$(grep '^cpu ' /proc/stat)"

# Calculate the total CPU time
total=$((user + nice + system + idle + iowait + irq + softirq + steal + guest + guest_nice))

# Calculate the CPU usage since we last checked
if [[ -f /tmp/cpu_usage.prev ]]; then
    prev_total=$(< /tmp/cpu_usage.prev)
    prev_idle=$(< /tmp/cpu_idle.prev)
    diff_idle=$((idle - prev_idle))
    diff_total=$((total - prev_total))
    diff_usage=$((1000 * (diff_total - diff_idle) / diff_total + 5))
    usage=$((diff_usage / 10))
else
    usage=0
fi

# Save the current values for the next check
echo "${total}" > /tmp/cpu_usage.prev
echo "${idle}" > /tmp/cpu_idle.prev

echo "🏭 ${usage}%"
echo "🏭 ${usage}%"

# Color calculation
if [ $usage -ge 80 ]; then
    echo "#FF0000"
elif [ $usage -ge 60 ]; then
    echo "#FFFF00"
elif [ $usage -ge 40 ]; then
    echo "#FFFFFF"
else
    echo "#00FF00"
fi
