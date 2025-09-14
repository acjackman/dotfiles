#!/usr/bin/env bash

# ZFS Management Script for zima1
# Provides common ZFS operations and maintenance commands

set -euo pipefail

POOL_NAME="zima1_stripe"

function show_usage() {
    cat << EOF
ZFS Management Script for zima1

Usage: $0 [COMMAND]

Commands:
    status      Show pool and dataset status
    health      Check pool health
    scrub       Start a scrub operation
    snapshots   List all snapshots
    backup      Create snapshot backup
    destroy     Destroy the pool (with confirmation)
    help        Show this help message

Examples:
    $0 status           # Show current status
    $0 health           # Check pool health
    $0 scrub            # Start scrub operation
    $0 backup media     # Create snapshot of media dataset
EOF
}

function check_pool_exists() {
    if ! zpool list "$POOL_NAME" 2>/dev/null; then
        echo "Error: ZFS pool '$POOL_NAME' does not exist"
        echo "Please run create_zfs_stripe_zima1.sh first"
        exit 1
    fi
}

function show_status() {
    check_pool_exists
    echo "=== ZFS Pool Status ==="
    sudo zpool status "$POOL_NAME"
    echo ""
    echo "=== ZFS Datasets ==="
    sudo zfs list -r "$POOL_NAME"
    echo ""
    echo "=== Pool Properties ==="
    sudo zpool get all "$POOL_NAME" | head -20
}

function check_health() {
    check_pool_exists
    echo "=== Pool Health Check ==="
    sudo zpool status "$POOL_NAME"
    
    health=$(sudo zpool get -H health "$POOL_NAME" | awk '{print $3}')
    echo ""
    echo "Pool health: $health"
    
    if [[ "$health" != "ONLINE" ]]; then
        echo "⚠️  Pool is not in ONLINE state"
        echo "Consider running a scrub: $0 scrub"
    else
        echo "✅ Pool is healthy"
    fi
}

function start_scrub() {
    check_pool_exists
    echo "Starting scrub operation on $POOL_NAME..."
    sudo zpool scrub "$POOL_NAME"
    echo "Scrub started. Check progress with: $0 status"
}

function list_snapshots() {
    check_pool_exists
    echo "=== ZFS Snapshots ==="
    sudo zfs list -t snapshot -r "$POOL_NAME"
}

function create_backup() {
    check_pool_exists
    dataset="${1:-}"
    if [[ -z "$dataset" ]]; then
        echo "Usage: $0 backup <dataset_name>"
        echo "Available datasets:"
        sudo zfs list -H -o name -r "$POOL_NAME" | grep -v "^$POOL_NAME$"
        exit 1
    fi
    
    full_dataset="$POOL_NAME/$dataset"
    timestamp=$(date +%Y%m%d_%H%M%S)
    snapshot_name="$full_dataset@backup_$timestamp"
    
    echo "Creating snapshot: $snapshot_name"
    sudo zfs snapshot "$snapshot_name"
    echo "✅ Snapshot created successfully"
}

function destroy_pool() {
    check_pool_exists
    echo "⚠️  WARNING: This will PERMANENTLY DESTROY the ZFS pool '$POOL_NAME'"
    echo "All data will be lost!"
    echo ""
    read -p "Type 'DESTROY' to confirm: " confirmation
    
    if [[ "$confirmation" == "DESTROY" ]]; then
        echo "Destroying pool $POOL_NAME..."
        sudo zpool destroy "$POOL_NAME"
        echo "✅ Pool destroyed"
    else
        echo "Operation cancelled"
    fi
}

# Main command handling
case "${1:-help}" in
    status)
        show_status
        ;;
    health)
        check_health
        ;;
    scrub)
        start_scrub
        ;;
    snapshots)
        list_snapshots
        ;;
    backup)
        create_backup "${2:-}"
        ;;
    destroy)
        destroy_pool
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Unknown command: ${1:-}"
        echo ""
        show_usage
        exit 1
        ;;
esac