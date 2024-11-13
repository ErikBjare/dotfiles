#!/bin/bash

CACHE_FILE="/tmp/btcPrice.json"
CACHE_TIME=60 # Cache for 1 minute

current_time=$(date +%s)

if [ -f "$CACHE_FILE" ]; then
    file_time=$(stat -c %Y "$CACHE_FILE")
    if [ $((current_time - file_time)) -lt $CACHE_TIME ]; then
        if btc_price=$(jq -r '.bitcoin.usd' "$CACHE_FILE" 2>/dev/null); then
            rounded_price=$(printf "%.0f" "$btc_price")
            echo "BTC \$$rounded_price"
            echo "BTC \$$rounded_price"
            echo "#00FF00"
            exit 0
        fi
    fi
fi

# Using CoinGecko API (free, no API key needed)
response=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd")
echo "$response" > "$CACHE_FILE"

if btc_price=$(echo "$response" | jq -r '.bitcoin.usd' 2>/dev/null); then
    rounded_price=$(printf "%.0f" "$btc_price")
    echo "BTC \$$rounded_price"
    echo "BTC \$$rounded_price"
    echo "#00FF00"
else
    echo "BTC $ (Error)"
    echo "BTC $ (Error)"
    echo "#FF0000"
fi
