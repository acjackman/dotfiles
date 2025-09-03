#!/usr/bin/env bash

# ZFS Pool Cleanup Script
# This script safely removes ZFS pools and cleans up any remaining ZFS state

set -euo pipefail

function show_usage() {
    cat << EOF
ZFS Pool Cleanup Script

Usage: $0 [OPTIONS] [POOL_NAME]

Options:
    -f, --force     Force cleanup without confirmation
    -a, --all       Clean up all pools
    -h, --help      Show this help message

Examples:
    $0 zima1_stripe         # Clean up specific pool
    $0 -f zima1_stripe      # Force cleanup without confirmation
    $0 -a                   # Clean up all pools (with confirmation)
EOF
}

FORCE=false
ALL_POOLS=false
POOL_NAME=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE=true
            shift
            ;;
        -a|--all)
            ALL_POOLS=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            POOL_NAME="$1"
            shift
            ;;
    esac
done

function cleanup_pool() {
    local pool="$1"
    
    echo "Cleaning up ZFS pool: $pool"
    
    # Export the pool first
    if zpool list "$pool" 2>/dev/null; then
        echo "Exporting pool: $pool"
        sudo zpool export "$pool" 2>/dev/null || true
    fi
    
    # Force destroy if pool still exists
    if zpool list "$pool" 2>/dev/null; then
        echo "Force destroying pool: $pool"
        sudo zpool destroy -f "$pool" 2>/dev/null || true
    fi
    
    echo "✅ Pool $pool cleaned up"
}

function cleanup_all_pools() {
    local pools=$(zpool list -H -o name 2>/dev/null || true)
    
    if [[ -z "$pools" ]]; then
        echo "No ZFS pools found"
        return 0
    fi
    
    echo "Found ZFS pools:"
    echo "$pools"
    echo ""
    
    if [[ "$FORCE" == "false" ]]; then
        echo "⚠️  WARNING: This will destroy ALL ZFS pools and their data!"
        read -p "Type 'DESTROY ALL' to confirm: " confirmation
        
        if [[ "$confirmation" != "DESTROY ALL" ]]; then
            echo "Operation cancelled"
            exit 1
        fi
    fi
    
    while IFS= read -r pool; do
        [[ -n "$pool" ]] && cleanup_pool "$pool"
    done <<< "$pools"
}

function cleanup_single_pool() {
    local pool="$1"
    
    if ! zpool list "$pool" 2>/dev/null; then
        echo "Pool '$pool' does not exist or is not imported"
        return 0
    fi
    
    if [[ "$FORCE" == "false" ]]; then
        echo "⚠️  WARNING: This will destroy ZFS pool '$pool' and ALL its data!"
        read -p "Type 'DESTROY' to confirm: " confirmation
        
        if [[ "$confirmation" != "DESTROY" ]]; then
            echo "Operation cancelled"
            exit 1
        fi
    fi
    
    cleanup_pool "$pool"
}

# Main execution
if [[ "$ALL_POOLS" == "true" ]]; then
    cleanup_all_pools
elif [[ -n "$POOL_NAME" ]]; then
    cleanup_single_pool "$POOL_NAME"
else
    echo "Error: Please specify a pool name or use --all"
    echo ""
    show_usage
    exit 1
fi

echo ""
echo "ZFS cleanup completed successfully!"

# Clean up any remaining ZFS modules/state
echo "Cleaning up ZFS kernel modules..."
sudo modprobe -r zfs 2>/dev/null || true
sudo modprobe zfs 2>/dev/null || true

echo "✅ ZFS cleanup complete"