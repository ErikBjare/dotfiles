#!/bin/bash
#
# Example usage: ./pinglog.sh google.com >> logfile.csv


HOST=$1

while true; do
    PING=$(ping -c 1 $HOST | egrep -o -m 1 "[\.0-9]+ ms")
    TIME=$(date +%s%N) # Nanoseconds since epoch

    echo "$TIME,$PING"
    sleep 1
done;


