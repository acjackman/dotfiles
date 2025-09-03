#!/usr/bin/env bash

# Complete ZFS Setup Script for zima1
# This script sets up the complete ZFS storage solution for the ARM project

set -euo pipefail

POOL_NAME="zima1_stripe"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function show_usage() {
    cat << EOF
Complete ZFS Setup Script for zima1

This script will:
1. Create a ZFS stripe pool using /dev/sda and /dev/sdb
2. Create datasets for media, docker, backups, etc.
3. Configure optimal settings for ARM (Automatic Ripping Machine)
4. Set up proper permissions

Usage: $0 [OPTIONS]

Options:
    -f, --force     Force creation (destroy existing pool if present)
    -s, --skip-datasets  Only create pool, skip dataset creation
    -h, --help      Show this help message

Prerequisites:
- ZFS utilities must be installed
- Drives /dev/sda and /dev/sdb must be available
- Script must be run with sudo privileges for ZFS operations
EOF
}

FORCE=false
SKIP_DATASETS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -s|--skip-datasets)
            SKIP_DATASETS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo "🚀 Starting ZFS setup for zima1..."
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check if ZFS is available
if ! command -v zpool &> /dev/null; then
    echo "❌ ZFS utilities not found. Please install ZFS first."
    echo "On Ubuntu/Debian: sudo apt install zfsutils-linux"
    exit 1
fi

# Check if drives exist
DRIVES=("/dev/sda" "/dev/sdb")
for drive in "${DRIVES[@]}"; do
    if [[ ! -b "$drive" ]]; then
        echo "❌ Drive $drive not found or not a block device"
        exit 1
    fi
done

echo "✅ Prerequisites check passed"
echo ""

# Step 1: Create ZFS stripe pool
echo "📦 Step 1: Creating ZFS stripe pool..."
if [[ "$FORCE" == "true" ]]; then
    "$SCRIPT_DIR/executable_create_zfs_stripe_zima1.sh" -f
else
    "$SCRIPT_DIR/executable_create_zfs_stripe_zima1.sh"
fi

if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create ZFS pool"
    exit 1
fi

echo ""

# Step 2: Create datasets (unless skipped)
if [[ "$SKIP_DATASETS" == "false" ]]; then
    echo "📁 Step 2: Creating ZFS datasets..."
    "$SCRIPT_DIR/executable_create_zfs_datasets.sh"
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to create ZFS datasets"
        exit 1
    fi
    echo ""
fi

# Step 3: Optimize for ARM workload
echo "⚙️  Step 3: Optimizing ZFS settings for ARM workload..."

# Set compression for all datasets
sudo zfs set compression=lz4 "$POOL_NAME"

# Optimize for large media files
sudo zfs set recordsize=1M "$POOL_NAME/media" 2>/dev/null || true
sudo zfs set atime=off "$POOL_NAME/media" 2>/dev/null || true

# Optimize for Docker workloads
sudo zfs set recordsize=64K "$POOL_NAME/docker" 2>/dev/null || true
sudo zfs set logbias=throughput "$POOL_NAME/docker" 2>/dev/null || true

echo "✅ ZFS optimization complete"
echo ""

# Step 4: Show final status
echo "📊 Final Setup Status:"
echo ""
sudo zpool status "$POOL_NAME"
echo ""
echo "Available mount points:"
sudo zfs list -r "$POOL_NAME" | grep -v "^NAME"

echo ""
echo "🎉 ZFS setup for zima1 completed successfully!"
echo ""
echo "Next steps for ARM setup:"
echo "1. Configure SMB shares to point to /zima1_stripe/media/"
echo "2. Set up Docker to use /zima1_stripe/docker/ for persistent data"
echo "3. Configure ARM to output to /zima1_stripe/media/movies/ and /zima1_stripe/media/tv/"
echo ""
echo "Management commands:"
echo "  $SCRIPT_DIR/executable_zfs_management.sh status   # Check status"
echo "  $SCRIPT_DIR/executable_zfs_management.sh health   # Health check"
echo "  $SCRIPT_DIR/executable_zfs_management.sh backup media  # Backup media dataset"