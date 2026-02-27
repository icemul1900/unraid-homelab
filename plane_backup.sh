#!/bin/bash
# Plane Backup Script
# Backs up: PostgreSQL dump, MinIO uploads, Redis RDB, config files
# Destination: /mnt/user/backups/Unraid/plane_data/
# Retention: 14 daily backups
# Log: /boot/logs/plane-backup.log

BACKUP_ROOT="/mnt/user/backups/Unraid/plane_data"
LOG="/boot/logs/plane-backup.log"
DATE=$(date +%Y-%m-%d)
BACKUP_DIR="${BACKUP_ROOT}/${DATE}"
RETAIN=14

MINIO_VOL="/var/lib/docker/volumes/248be645bad7947138f4304e5d45e9764de2f027d48854be0bb9fc4acfe88d6a/_data"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"
}

fail() {
    log "ERROR: $*"
    exit 1
}

mkdir -p "$BACKUP_DIR" || fail "Cannot create backup dir: $BACKUP_DIR"
mkdir -p "$(dirname "$LOG")"

log "===== Plane backup started (${DATE}) ====="

# ── 1. PostgreSQL dump ───────────────────────────────────────────────────────
log "Dumping PostgreSQL..."
docker exec z-plane-db pg_dump -U plane -d plane --format=custom \
    > "${BACKUP_DIR}/plane_postgres.dump" 2>>"$LOG" \
    || fail "pg_dump failed"
PG_SIZE=$(du -sh "${BACKUP_DIR}/plane_postgres.dump" | cut -f1)
log "  PostgreSQL dump OK (${PG_SIZE})"

# ── 2. MinIO uploads (file attachments) ─────────────────────────────────────
log "Backing up MinIO uploads..."
if [ -d "$MINIO_VOL" ]; then
    tar -czf "${BACKUP_DIR}/plane_minio.tar.gz" -C "$MINIO_VOL" . 2>>"$LOG" \
        || fail "MinIO tar failed"
    MINIO_SIZE=$(du -sh "${BACKUP_DIR}/plane_minio.tar.gz" | cut -f1)
    log "  MinIO backup OK (${MINIO_SIZE})"
else
    log "  WARNING: MinIO volume path not found, skipping: ${MINIO_VOL}"
fi

# ── 3. Redis RDB snapshot ────────────────────────────────────────────────────
log "Backing up Redis RDB..."
REDIS_RDB="/mnt/user/appdata/plane-stack/redisdata/dump.rdb"
if [ -f "$REDIS_RDB" ]; then
    cp "$REDIS_RDB" "${BACKUP_DIR}/plane_redis.rdb" 2>>"$LOG" \
        || fail "Redis copy failed"
    log "  Redis backup OK"
else
    log "  INFO: No Redis dump.rdb found (normal if Redis hasn't flushed yet)"
fi

# ── 4. Config files ──────────────────────────────────────────────────────────
log "Backing up config files..."
cp /mnt/user/appdata/plane/start.sh "${BACKUP_DIR}/start.sh" 2>>"$LOG" \
    && log "  start.sh OK" \
    || log "  WARNING: start.sh not found"
cp /boot/config/plugins/dockerMan/templates-user/my-plane.xml "${BACKUP_DIR}/my-plane.xml" 2>>"$LOG" \
    && log "  my-plane.xml OK" \
    || log "  WARNING: my-plane.xml not found"

# ── 5. Write restore notes ───────────────────────────────────────────────────
cat > "${BACKUP_DIR}/RESTORE.md" << EOF
# Plane Backup — ${DATE}

## Contents
- plane_postgres.dump — pg_dump custom format (restore with pg_restore)
- plane_minio.tar.gz  — MinIO file attachments
- plane_redis.rdb     — Redis snapshot (optional, cache only)
- start.sh            — Patched AIO start script (port-aware redirects)
- my-plane.xml        — Unraid DockerMan template

## Restore PostgreSQL
\`\`\`bash
docker exec -i z-plane-db pg_restore -U plane -d plane --clean < plane_postgres.dump
\`\`\`

## Restore MinIO
\`\`\`bash
MINIO_VOL=\$(docker inspect z-plane-minio --format '{{range .Mounts}}{{.Source}}{{end}}')
tar -xzf plane_minio.tar.gz -C "\$MINIO_VOL"
\`\`\`
EOF
log "  RESTORE.md written"

# ── 6. Prune old backups (keep most recent RETAIN days) ─────────────────────
log "Pruning backups older than ${RETAIN} days..."
PRUNED=0
while IFS= read -r old_dir; do
    rm -rf "$old_dir" && PRUNED=$((PRUNED + 1))
done < <(ls -1dt "${BACKUP_ROOT}"/????-??-?? 2>/dev/null | tail -n +$((RETAIN + 1)))
[ "$PRUNED" -gt 0 ] && log "  Removed ${PRUNED} old backup(s)" || log "  Nothing to prune"

# ── 7. Summary ───────────────────────────────────────────────────────────────
TOTAL=$(du -sh "$BACKUP_DIR" | cut -f1)
log "===== Plane backup complete — ${TOTAL} written to ${BACKUP_DIR} ====="
