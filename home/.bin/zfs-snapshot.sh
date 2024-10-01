#!/bin/bash

# ZFS Snapshot Management Script
#
# This script creates daily and monthly snapshots of ZFS datasets.
# It is designed to run as a systemd user service with limited permissions.
#
# Functionality:
# - Creates daily snapshots for all datasets under zroot
# - Creates monthly snapshots if one doesn't exist for the current month
# - Attempts to remove daily snapshots older than 30 days (requires zfs destroy permission)
#
# Usage:
# - Run this script daily via a systemd user service or cron job
# - Ensure the user has permission to create ZFS snapshots
# - Note: Snapshot deletion requires additional permissions and is disabled if not available

# exit on error
set -e

# Check if we have permission to destroy snapshots
can_destroy=false
if zfs allow | grep -q "destroy"; then
    can_destroy=true
fi

# Function to create a recursive snapshot
create_snapshot() {
    local prefix=$1
    local snapshot_name="${prefix}-$(date +%Y-%m-%d)"
    local datasets=$(zfs list -H -o name -r zroot)
    local snapshot_created=false

    for dataset in $datasets; do
        if ! zfs list -H -t snapshot -o name | grep -q "${dataset}@${snapshot_name}"; then
            zfs snapshot "${dataset}@${snapshot_name}"
            echo "Created snapshot: ${dataset}@${snapshot_name}"
            snapshot_created=true
        else
            echo "Snapshot already exists: ${dataset}@${snapshot_name}"
        fi
    done

    if [ "$snapshot_created" = true ]; then
        echo "Created recursive snapshot for prefix: ${prefix}"
    else
        echo "No new snapshots were created for prefix: ${prefix}"
    fi
}

# Create daily snapshot
create_snapshot "daily"

# Check if a monthly snapshot exists for the current month
current_year_month=$(date +%Y-%m)
if ! zfs list -H -t snapshot -o name | grep -q "monthly-${current_year_month}"; then
    create_snapshot "monthly"
fi

# Attempt to remove daily snapshots older than 30 days if we have permission
if [ "$can_destroy" = true ]; then
    current_date=$(date +%s)
    zfs list -H -t snapshot -o name,creation | grep 'zroot@daily-' | while read -r snapshot creation; do
        creation_date=$(date -d "$creation" +%s)
        age_days=$(( (current_date - creation_date) / 86400 ))

        if [[ $age_days -gt 30 ]]; then
            zfs destroy "$snapshot"
            echo "Removed old daily snapshot: $snapshot"
        fi
    done
    echo "Snapshot process completed. Daily snapshots older than 30 days have been removed. Monthly snapshots are preserved."
else
    echo "Snapshot process completed. Snapshot deletion was skipped due to insufficient permissions."
    echo "To enable deletion, ensure this script has the 'destroy' permission for ZFS."
fi
