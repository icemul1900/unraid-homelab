#!/bin/bash
mkdir -p /boot/logs
exec >> /boot/logs/zfs-snapshot.log 2>&1
echo "=== ZFS Snapshot: $(date) ==="

# zpool status -x with no pool arg returns "all pools are healthy" when healthy.
# Passing a specific pool name returns "pool '<name>' is healthy" — wrong string.
POOL_STATUS=$(zpool status -x)
if [ "${POOL_STATUS}" != "all pools are healthy" ]; then
    echo "ERROR: Pool not healthy: ${POOL_STATUS}. Aborting."
    exit 1
fi

DATASETS=("apps/appdata" "apps/system")
KEEP=7

for ds in "${DATASETS[@]}"; do
    SNAP_NAME="daily-$(date +%F)"
    if zfs list -t snapshot "${ds}@${SNAP_NAME}" > /dev/null 2>&1; then
        echo "Snapshot ${ds}@${SNAP_NAME} already exists, skipping."
        continue
    fi
    zfs snapshot "${ds}@${SNAP_NAME}" || { echo "ERROR: Failed to create ${ds}@${SNAP_NAME}" >&2; continue; }
    echo "Created ${ds}@${SNAP_NAME}"
    zfs list -H -t snapshot -o name -S creation -r "${ds}" | grep "@daily-" | tail -n +$((KEEP + 1)) | while read snap; do
        zfs destroy "${snap}" && echo "Destroyed ${snap}" || echo "WARNING: Failed to destroy ${snap}" >&2
    done
done
echo "=== Completed: $(date) ==="
