#!/usr/bin/env bash

# ZFS Stripe Pool Creation Script for zima1
# This script creates a ZFS stripe pool using the two Lexar SSD NS100 drives
# Drives detected: /dev/sda and /dev/sdb (Lexar SSD NS100 .13)

set -euo pipefail

POOL_NAME="zima1_stripe"
DRIVES=("/dev/sda" "/dev/sdb")

echo "Creating ZFS stripe pool: $POOL_NAME"
echo "Using drives: ${DRIVES[*]}"

# Verify drives exist
for drive in "${DRIVES[@]}"; do
    if [[ ! -b "$drive" ]]; then
        echo "Error: Drive $drive not found or not a block device"
        exit 1
    fi
done

# Check if pool already exists
if zpool list "$POOL_NAME" 2>/dev/null; then
    echo "Warning: Pool $POOL_NAME already exists"
    echo "Use the -f flag to force creation (will destroy existing pool)"
    
    if [[ "${1:-}" != "-f" ]]; then
        echo "Exiting. Use '$0 -f' to force creation"
        exit 1
    fi
    
    echo "Destroying existing pool $POOL_NAME..."
    sudo zpool destroy "$POOL_NAME"
fi

# Create the stripe pool
echo "Creating ZFS stripe pool..."
sudo zpool create -f "$POOL_NAME" "${DRIVES[@]}"

# Verify pool creation
if zpool list "$POOL_NAME" 2>/dev/null; then
    echo "✅ Successfully created ZFS stripe pool: $POOL_NAME"
    echo ""
    echo "Pool status:"
    sudo zpool status "$POOL_NAME"
    echo ""
    echo "Pool properties:"
    sudo zpool get all "$POOL_NAME"
else
    echo "❌ Failed to create ZFS stripe pool"
    exit 1
fi

echo ""
echo "Pool $POOL_NAME is ready for use!"
echo "Mount point: /$POOL_NAME"