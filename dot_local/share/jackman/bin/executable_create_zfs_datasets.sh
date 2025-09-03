#!/usr/bin/env bash

# ZFS Dataset Creation Script for zima1
# This script creates common ZFS datasets on the zima1_stripe pool

set -euo pipefail

POOL_NAME="zima1_stripe"

# Check if pool exists
if ! zpool list "$POOL_NAME" 2>/dev/null; then
    echo "Error: ZFS pool '$POOL_NAME' does not exist"
    echo "Please run create_zfs_stripe_zima1.sh first"
    exit 1
fi

echo "Creating ZFS datasets on pool: $POOL_NAME"

# Common datasets for ARM (Automatic Ripping Machine) setup
DATASETS=(
    "media"           # Main media storage
    "media/movies"    # Movie storage
    "media/tv"        # TV show storage
    "media/music"     # Music storage
    "media/books"     # Book/audiobook storage
    "backups"         # Backup storage
    "docker"          # Docker container data
    "downloads"       # Download staging area
    "temp"            # Temporary storage
)

for dataset in "${DATASETS[@]}"; do
    full_dataset="$POOL_NAME/$dataset"
    
    if zfs list "$full_dataset" 2>/dev/null; then
        echo "Dataset $full_dataset already exists, skipping..."
        continue
    fi
    
    echo "Creating dataset: $full_dataset"
    sudo zfs create "$full_dataset"
    
    # Set appropriate permissions for media directories
    if [[ "$dataset" == media* ]]; then
        echo "Setting permissions for media dataset: $full_dataset"
        sudo chmod 755 "/$full_dataset"
        # Optionally set ownership to current user
        # sudo chown $USER:$USER "/$full_dataset"
    fi
done

echo ""
echo "✅ ZFS datasets created successfully!"
echo ""
echo "Available datasets:"
sudo zfs list -r "$POOL_NAME"

echo ""
echo "Dataset mount points:"
for dataset in "${DATASETS[@]}"; do
    echo "  /$POOL_NAME/$dataset"
done

echo ""
echo "To set custom properties on datasets, use:"
echo "  sudo zfs set compression=lz4 $POOL_NAME/media"
echo "  sudo zfs set recordsize=1M $POOL_NAME/media  # Good for large files"
echo "  sudo zfs set atime=off $POOL_NAME/media      # Improve performance"