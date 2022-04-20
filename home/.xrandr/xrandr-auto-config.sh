#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

HOSTNAME=$(hostnamectl hostname --static)
SCRIPT="$SCRIPT_DIR/$HOSTNAME.sh"

if [ -f $SCRIPT ]; then
    echo "Running $SCRIPT..."
    $SCRIPT
else
    echo "Error: No script for device $HOSTNAME";
    exit 1
fi
