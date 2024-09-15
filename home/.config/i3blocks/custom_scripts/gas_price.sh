#!/bin/bash

APIKEY="8AKPUEVKW3UNFKIXRTS5HW5WMWG1UX68QH"
CACHE_FILE="/tmp/gasPrice.json"
CACHE_TIME=600 # Cache for 10 minutes

current_time=$(date +%s)

if [ -f "$CACHE_FILE" ]; then
    file_time=$(stat -c %Y "$CACHE_FILE")
    if [ $((current_time - file_time)) -lt $CACHE_TIME ]; then
        gas_price=$(jq -r '.result.SafeGasPrice' "$CACHE_FILE")
        gas_price_rounded=$(printf "%.0f" "$gas_price")
        echo "⛽ $gas_price_rounded"
        echo "⛽ $gas_price_rounded"
        color_pick "$gas_price_rounded"
        exit 0
    fi
fi

response=$(curl -s "https://api.etherscan.io/api?module=gastracker&action=gasoracle&apikey=$APIKEY")
echo "$response" > "$CACHE_FILE"

gas_price=$(echo "$response" | jq -r '.result.SafeGasPrice')
gas_price_rounded=$(printf "%.0f" "$gas_price")

echo "⛽ $gas_price_rounded"
echo "⛽ $gas_price_rounded"
color_pick "$gas_price_rounded"

function color_pick() {
    local value=$1
    if (( $(echo "$value > 100" | bc -l) )); then
        echo "#FFFFFF"
    elif (( $(echo "$value < 1" | bc -l) )); then
        echo "#0000FF"
    else
        local r g b
        r=$(printf "%.0f" $(echo "255 * ($value - 1) / 99" | bc -l))
        g=$(printf "%.0f" $(echo "255 * (100 - $value) / 99" | bc -l))
        b=85
        printf "#%02X%02X%02X\n" $r $g $b
    fi
}
