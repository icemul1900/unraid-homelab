# Session Summary — 2026-02-27 (Session 8)

## What Was Accomplished Today

### 1. Plane Docker Panel Fixed
- **Root cause identified:** The `net.unraid.docker.managed` label was set to the string `"true"`. Unraid's `DockerClient.php` requires the value `"dockerman"` for a container to be treated as a managed entry. The wrong value caused approximately 40 stale ghost entries to accumulate in `/var/lib/docker/containers/*/docker.json` from iterative Plane stack rebuilds.
- **Fix applied:** Corrected the label value in `my-plane.xml` ExtraParams to `--label "net.unraid.docker.managed=dockerman"`. Cleaned all stale ghost entries from docker.json manually via SSH.
- **Result:** Plane now appears as a single managed icon with "up-to-date" status on the Unraid Docker dashboard.

### 2. Plane Auth Redirect Port Bug Fixed
- **Root cause identified:** The upstream `start.sh` inside the `makeplane/plane-aio-community` container constructs `WEB_URL` and `CORS_ALLOWED_ORIGINS` using `DOMAIN_NAME` only, without any port. The `DOMAIN_NAME` validation function rejects values containing a colon (i.e., `IP:port` format), making it impossible to pass a port through that variable. As a result, OAuth and CSRF redirects sent users to port 80 instead of the actual service port 8083, breaking sign-in and sign-out.
- **Fix applied:** Patched `start.sh` to read an additional `APP_PORT` environment variable and compute a `port_suffix` (empty string if port is 80 or 443, otherwise `:$APP_PORT`). The patched script was saved to `/mnt/user/appdata/plane/start.sh` on the host and bind-mounted into the container at `/app/start.sh:ro`.
- `my-plane.xml` updated with: `APP_PORT=8083` config variable and a volume mount entry for the patched start script.
- `plane-start.sh` committed to the repo as the canonical patched script.
- **Result:** Sign-in and sign-out now correctly redirect to `http://192.168.128.43:8083/`.

### 3. Plane LAB Project Restored
- 47 issues created via the Plane REST API against the "home" workspace, LAB project.
- Issue distribution: 35 Done (completed ops history migrated from previous context files), 10 Todo (open pending tasks), 2 Cancelled.
- API key stored at `C:\AI tools\secrets\plane_api.txt`.

### 4. Automated Plane Backup Configured
- `plane_backup.sh` written and deployed to Unraid User Scripts.
- **What it backs up:**
  - PostgreSQL database dump via `docker exec z-plane-db pg_dump` (pg_dump custom format for efficient restore).
  - MinIO Docker volume (file attachments) as `tar.gz`.
  - Redis RDB snapshot (optional, cache-only data).
  - Config files: `start.sh` and `my-plane.xml`.
  - Self-contained `RESTORE.md` with exact restore commands written into each backup directory.
- **Destination:** `/mnt/user/backups/Unraid/plane_data/<date>/`
- **Log:** `/boot/logs/plane-backup.log`
- **Retention:** 14 daily backups.
- **Schedule:** Daily at 3:15 AM via `/etc/cron.d/root`.
- **Test run confirmed:** 840K written successfully.
- Script committed to the repo as `plane_backup.sh`.

---

## Key Decisions Made

1. **Bind-mount over image modification for start.sh patch:** Rather than building a custom Docker image with the patched `start.sh`, the fix is applied by bind-mounting the patched file from the host. This keeps the approach upgrade-safe (the mount overrides the container's file on every start) and avoids maintaining a custom image registry. Trade-off: the bind-mount must remain in place; if the Unraid template is ever reset, the volume mount must be re-added.

2. **`APP_PORT` as the authoritative port variable:** Adding `APP_PORT` as an explicit Unraid template variable (visible in the "always" display tier) makes the port configuration self-documenting and surfaced to the user rather than buried in ExtraParams.

3. **pg_dump custom format for PostgreSQL backup:** Chosen over plain SQL for space efficiency and the ability to do selective table restores via `pg_restore`. The RESTORE.md in each backup directory documents the exact restore invocation.

4. **14-day backup retention for Plane:** Balanced against available disk space. Plane data is primarily text (issues, comments), so backup sizes are expected to remain small (~1MB/day). 14 days provides two weeks of rollback capability.

5. **Stale docker.json ghost entries cleaned manually:** The ~40 ghost entries were a side effect of multiple iterations of the Plane stack being created and destroyed during initial deployment. Cleaning them once was sufficient; the root cause (wrong label value) has been corrected.

---

## Open Questions / Next Steps

- **[CRITICAL] Implement off-server ZFS backup via Sanoid+Syncoid.** Now 6 sessions overdue. All application-level backups (Plane) are stored on the same Unraid array. A single-disk failure or array-wide event destroys everything.
- **[CRITICAL] Configure Tailscale ACLs.** Exit node active with no ACL policy = all Tailnet peers have full LAN access.
- **[HIGH] Disable Tailscale key expiry on Unraid node.** Node will lose connectivity at key expiry without manual renewal.
- **[HIGH] Audit binhex-delugevpn.** Verify kill switch is active, `LAN_NETWORK=192.168.128.0/24` is set, and WebUI is not publicly exposed.
- **[HIGH] Audit/replace Seerr image.** `ghcr.io/seerr-team/seerr` is a third-party fork holding Plex, Radarr, and Sonarr API keys.
- **[MEDIUM] MinIO volume path hardcoded in plane_backup.sh.** The volume hash (`248be645...`) will change if the MinIO container is ever recreated. Future improvement: use `docker inspect z-plane-minio --format '{{range .Mounts}}{{.Source}}{{end}}'` dynamically in the script.
- **[MEDIUM] Plane SMTP password in my-plane.xml is in plaintext.** The Gmail App Password is visible in the XML template checked into git. Consider gitignoring `my-plane.xml` or using Unraid's secret store if one becomes available.
- **[MEDIUM] Replicate HEVC Custom Format to Sonarr via Recyclarr.**
- **[MEDIUM] Add Pi-hole secondary container.**
- **[MEDIUM] ZFS: set compression=zstd and recordsize=16K on apps/appdata.**
- **[MEDIUM] Add ZFS snapshot failure alerting.**
- **[MEDIUM] Configure HSTS at Cloudflare edge.**

---

## Lessons Learned

1. **Unraid DockerClient.php label requirement:** The `net.unraid.docker.managed` label must be set to the string `"dockerman"` — not `"true"`, not `"1"`, not `"yes"`. Any other value causes the container to not be recognized as managed, resulting in phantom/ghost entries multiplying on each Docker operation. This is undocumented behavior that took significant debugging to surface.

2. **Plane AIO start.sh port limitation:** The Plane AIO community image's `start.sh` has a hard-coded assumption that the service runs on port 80 or 443. There is no upstream mechanism to configure a non-standard port without patching the script. The bind-mount approach is the least invasive fix. Watching for upstream changes to `start.sh` in new image releases is important, as the patched file could become stale after an image update.

3. **pg_dump custom format requires pg_restore (not psql):** The custom format produces a non-human-readable binary. Restore with `pg_restore -U plane -d plane --clean < plane_postgres.dump`, not `psql`. This is documented in the RESTORE.md written by the backup script.

4. **Docker volume path stability:** Docker named volume paths under `/var/lib/docker/volumes/` use a content-addressed hash. If a container and its volume are destroyed and recreated, the path changes. For production backups, always use `docker inspect` to resolve the current path dynamically rather than hardcoding it.

---

## Files Updated

- `/C:/AI tools/Home/Unraid/my-plane.xml` — Added `APP_PORT` variable, start.sh volume mount, corrected `net.unraid.docker.managed=dockerman` label.
- `/C:/AI tools/Home/Unraid/plane-start.sh` — New file: patched Plane AIO start.sh with APP_PORT/port_suffix logic.
- `/C:/AI tools/Home/Unraid/plane_backup.sh` — New file: automated backup script for Plane stack.
- `/C:/AI tools/Home/Unraid/GEMINI.md` — Appended 2026-02-27 session entries, updated Goals Met and Next Steps.
- `/C:/AI tools/Home/Unraid/unraid_agent.md` — Appended 2026-02-27 log entries, updated Goals Met.
- `/C:/AI tools/Home/Unraid/agents.md` — Appended 2026-02-27 session log, updated Goals Met and Next Steps.
- `C:/Users/bthomas/.claude/projects/C--AI-tools-Home-Unraid/memory/MEMORY.md` — Added Plane section with critical fix details and backup info.
