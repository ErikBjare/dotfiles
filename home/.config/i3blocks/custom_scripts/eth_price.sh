#!/bin/bash

APIKEY="8AKPUEVKW3UNFKIXRTS5HW5WMWG1UX68QH"
CACHE_FILE="/tmp/ethPrice.json"
CACHE_TIME=60 # Cache for 1 minute

current_time=$(date +%s)

if [ -f "$CACHE_FILE" ]; then
    file_time=$(stat -c %Y "$CACHE_FILE")
    if [ $((current_time - file_time)) -lt $CACHE_TIME ]; then
        if eth_price=$(jq -r '.result.ethusd' "$CACHE_FILE" 2>/dev/null); then
            rounded_price=$(printf "%.0f" "$eth_price")
            echo "ETH \$$rounded_price"
            echo "ETH \$$rounded_price"
            echo "#00FF00"
            exit 0
        fi
    fi
fi

response=$(curl -s "https://api.etherscan.io/api?module=stats&action=ethprice&apikey=$APIKEY")
echo "$response" > "$CACHE_FILE"

if eth_price=$(echo "$response" | jq -r '.result.ethusd' 2>/dev/null); then
    rounded_price=$(printf "%.0f" "$eth_price")
    echo "ETH \$$rounded_price"
    echo "ETH \$$rounded_price"
    echo "#00FF00"
else
    echo "ETH $ (Error: $(echo "$response" | jq -r '.message'))"
    echo "ETH $ (Error: $(echo "$response" | jq -r '.message'))"
    echo "#FF0000"
fi
