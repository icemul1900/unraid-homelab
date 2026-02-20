#!/bin/bash
# ZFS Daily Snapshot & Rotate
# Keep 7 days of snapshots
DATASETS=("apps/appdata" "apps/system")
KEEP=7

for ds in "${DATASETS[@]}"; do
    # Create new snapshot
    SNAP_NAME="daily-$(date +%F)"
    echo "Taking snapshot $ds@$SNAP_NAME"
    zfs snapshot "$ds@$SNAP_NAME"
    
    # Delete old snapshots
    echo "Cleaning up old snapshots for $ds"
    # List snapshots, newest first, skip the first 7, delete the rest
    zfs list -H -t snapshot -o name -S creation -r "$ds" | grep "daily-" | tail -n +$((KEEP + 1)) | xargs -n 1 zfs destroy 2>/dev/null
done
echo "ZFS Snapshot Task Completed: $(date)"
