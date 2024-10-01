#!/bin/bash

# Bluetooth device address
DEVICE_ADDRESS="F4:4E:FD:C3:70:8B"

# Log file
LOG_FILE="/tmp/bluetooth_toggle.log"

# State file
STATE_FILE="/tmp/bluetooth_toggle_state"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to check Bluetooth status with timeout
check_bluetooth_status() {
    timeout 5s bluetoothctl show | grep "Powered:" | awk '{print $2}' | tr -d '\n'
}

# Function to check if the device is connected with timeout
is_connected() {
    timeout 5s bluetoothctl info $DEVICE_ADDRESS | grep -q "Connected: yes"
}

# Function to toggle the connection
toggle_connection() {
    if is_connected; then
        log_message "Attempting to disconnect..."
        bluetoothctl disconnect $DEVICE_ADDRESS
    else
        log_message "Attempting to connect..."
        bluetoothctl connect $DEVICE_ADDRESS
    fi
    sleep 1
    if is_connected; then
        echo "ON" > "$STATE_FILE"
        echo "BT: ON"
    else
        echo "OFF" > "$STATE_FILE"
        echo "BT: OFF"
    fi
    pkill -RTMIN+11 i3blocks
}

# Log every time the script is called
log_message "Script called with BLOCK_BUTTON=${BLOCK_BUTTON}"

# Check Bluetooth status
bt_status=$(check_bluetooth_status)

if [ "$bt_status" != "yes" ]; then
    log_message "Bluetooth is powered off"
    echo "BT: OFF"
else
    # Handle click events
    if [[ "${BLOCK_BUTTON}" == "1" ]]; then
        log_message "Toggle button clicked"
        toggle_connection
    else
        # Display current status
        if [ -f "$STATE_FILE" ]; then
            state=$(cat "$STATE_FILE")
            echo "BT: $state"
        elif is_connected; then
            log_message "Status: Connected"
            echo "BT: ON"
        else
            log_message "Status: Disconnected"
            echo "BT: OFF"
        fi
    fi
fi

log_message "Script execution completed"
