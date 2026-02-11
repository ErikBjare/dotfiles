#!/bin/bash

# Configuration
CACHE_DIR="/tmp/price_cache"
CACHE_TIME=60  # Cache for 1 minute
mkdir -p "$CACHE_DIR"

# Usage: ./price.sh <asset>
# Example: ./price.sh btc

asset="${1:-btc}"  # Default to BTC if no argument provided

get_crypto_price() {
    local id="$1"
    local symbol="$2"
    local cache_file="$CACHE_DIR/${id}_price.json"

    # Check cache
    if [ -f "$cache_file" ]; then
        if [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt $CACHE_TIME ]; then
            if price=$(jq -r ".[\"$id\"].usd" "$cache_file" 2>/dev/null); then
                echo "$price"
                return 0
            fi
        fi
    fi

    # Fetch new data
    response=$(curl -s "https://api.coingecko.com/api/v3/simple/price?ids=$id&vs_currencies=usd")
    if [ $? -eq 0 ] && [ -n "$response" ]; then
        echo "$response" > "$cache_file"
        price=$(echo "$response" | jq -r ".[\"$id\"].usd" 2>/dev/null)
        if [ -n "$price" ] && [ "$price" != "null" ]; then
            echo "$price"
            return 0
        fi
    fi
    return 1
}

get_stock_price() {
    local symbol="$1"
    local cache_file="$CACHE_DIR/${symbol}_price.json"

    # Check cache
    if [ -f "$cache_file" ]; then
        if [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt $CACHE_TIME ]; then
            if price=$(jq -r '.price' "$cache_file" 2>/dev/null); then
                echo "$price"
                return 0
            fi
        fi
    fi

    # Using Alpha Vantage API
    ALPHAVANTAGE_API_KEY="demo" # Replace with your API key
    response=$(curl -s "https://www.alphavantage.co/query?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$ALPHAVANTAGE_API_KEY")
    if [ $? -eq 0 ]; then
        echo "$response" > "$cache_file"
        if price=$(echo "$response" | jq -r '."Global Quote"."05. price"' 2>/dev/null); then
            echo "$price"
            return 0
        fi
    fi
    return 1
}

format_output() {
    local symbol="$1"
    local price="$2"
    if [ -n "$price" ] && [ "$price" != "null" ]; then
        local rounded_price
        rounded_price=$(printf "%.0f" "$price")
        echo "$symbol \$$rounded_price"
        echo "$symbol \$$rounded_price"
        echo "#00FF00"
    else
        echo "$symbol Error"
        echo "$symbol Error"
        echo "#FF0000"
    fi
}

# Asset configurations
case "$asset" in
    "btc")
        if price=$(get_crypto_price "bitcoin" "BTC"); then
            format_output "BTC" "$price"
        else
            echo "BTC Error"
            echo "BTC Error"
            echo "#FF0000"
        fi
        ;;
    "eth")
        if price=$(get_crypto_price "ethereum" "ETH"); then
            format_output "ETH" "$price"
        else
            echo "ETH Error"
            echo "ETH Error"
            echo "#FF0000"
        fi
        ;;
    "spy")
        if price=$(get_stock_price "SPY"); then
            format_output "SPY" "$price"
        else
            echo "SPY Error"
            echo "SPY Error"
            echo "#FF0000"
        fi
        ;;
    "gold")
        price=$(get_crypto_price "tether-gold" "XAUT")
        format_output "GOLD" "$price"
        ;;
    *)
        echo "Unknown asset: $asset"
        echo "Unknown asset: $asset"
        echo "#FF0000"
        ;;
esac
