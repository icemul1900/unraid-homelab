# GEMINI - Unraid Management State

This file defines the foundational mandates, architectural state, and operational history for Gemini agents managing the Unraid Homelab.

## Core Mandates
- **Single Source of Truth:** All technical findings, IP maps, and architectural decisions MUST be synchronized with `unraid_agent.md`.
- **Project Tracking (Plane):** The Plane instance at `http://192.168.128.43:8083` (Project: LAB) is the authoritative visual state for all tasks. Every task started or completed MUST be synchronized with Plane.
- **SSH Protocol:** Remote management is performed via SSH to `192.168.128.43`. Root access is verified using SSH keys.
- **Atomic Template Updates:** When modifying Unraid Docker XML templates, always verify XML integrity and create a `.bak` on the host before overwriting.
- **Standardized Paths:** 
  - Host Appdata: `/mnt/user/appdata/`
  - Host Media: `/mnt/user/plex/`
  - Container Unified Data: `/data` (for *arr stack)

## Current Architectural State

### Server Configuration
- **Host:** Tower (192.168.128.43)
- **OS:** Unraid 7.2.3
- **ZFS Pool `apps`:** 1TB Mirror (sdc1/sdd1). `atime=off`, `autotrim=on`.
- **ZFS ARC:** Capped at 8GB via `/etc/modprobe.d/zfs.conf`.
- **Appdata Share:** Set to `Cache: Only` on `apps` pool.

### Network Registry (icemulnet)
- **Subnet:** 172.18.0.0/24
- **Gateway:** 172.18.0.1
- **Static Map:**
  - .2: Unraid-Cloudflared-Tunnel
  - .3: prowlarr
  - .4: seerr
  - .5: NginxProxyManager
  - .6: sonarr
  - .7: binhex-delugevpn
  - .8: jellyfin
  - .9: radarr
  - .10: Mealie
  - .11: wger-redis
  - .12: wger-db
  - .13: wger-web
  - .14: wger-nginx
  - .15: zuzz-proxy
  - **Plane Stack:**
    - .20: z-plane-db (Postgres)
    - .21: z-plane-redis (Valkey)
    - .22: z-plane-mq (RabbitMQ)
    - .23: z-plane-minio (MinIO)
    - .24: Plane-API
    - .25: Plane-Web
    - .26: Plane (Proxy/WebUI)
    - .27: Plane-Worker
    - .28: Plane-Beat
    - .29: Plane-Migrator
    - .30: Plane-Space
    - .31: Plane-Admin
    - .32: Plane-Live

## Recent Modifications & Fixes
- **[2026-02-23] Network Migration:** Migrated `icemulnet` to a `/24` subnet (`172.18.0.0/24`) to avoid collisions.
- **[2026-02-23] Security Hardening:** Removed Prowlarr NPM proxy (internal-only) and added global security headers.
- **[2026-02-23] Plex Configuration Fixed:** Upload rate (450000 → 4500 Kbps), memory limit (4g), and healthcheck added.
- **[2026-02-23] Arr Stack Hardened:** Added memory limits (1g), healthchecks, and UMASK (002) to Radarr and Sonarr templates.
- **[2026-02-23] ZFS Protection:** Improved `zfs_snapshot.sh` with exit-code checks, pool health gate, and persistent logging to `/boot/logs/zfs-snapshot.log`.
- **[2026-02-23] ZFS Optimization:** Set `xattr=sa acltype=posixacl dnodesize=auto compression=lz4` on `apps/appdata` and `apps/system`.
- **[2026-02-24] ZFS Script v3:** CRITICAL fix — pool health check `zpool status -x apps` was wrong (returns pool-specific string). Changed to `zpool status -x` (no arg). Added `mkdir -p /boot/logs`. Script was aborting every run since v2 rewrite.
- **[2026-02-24] Plex Template v3:** UMASK 022→002, stale PLEX_CLAIM cleared, `--memory-swap=4g` added, `--health-start-period=30s` added.
- **[2026-02-24] Arr Templates v3:** `--memory-swap=1g` and `--health-start-period=30s` added to Radarr and Sonarr.
- **[2026-02-24] NPM Headers v3:** Removed deprecated `X-XSS-Protection` header from `npm_http.conf`.
- **[2026-02-24] Permissions Repair:** Recursive `chown nobody:users` and `chmod 777` applied to `/mnt/user/plex/tv/` and `/mnt/user/plex/movies/` to resolve access issues.
- **[2026-02-25] Deluge Cleanup:** Identified and removed 32 broken (0% progress) torrents from Deluge following library reorganization. Empty `111_` seeding folders identified; full library consolidation confirmed.
- **[2026-02-25] Jellyfin Optimized:** Recreated Jellyfin container with `/dev/dri` hardware acceleration, `/dev/shm` RAM transcoding, 4g memory limits, and updated library mappings.
- **[2026-02-25] Zuzz Stream Automation:** Deployed `zuzz-proxy` PHP container on port 8082 (Internal: 172.18.0.15).
- **[2026-02-26] Zuzz/Jellyfin Guide Fixed (Session 6):**
  - M3U uses stable `tvg-name` (channel name only) — dynamic names were creating duplicate Jellyfin channels.
  - EPG `<programme>` start time uses stream's `ts` Unix timestamp — hardcoded midnight caused Jellyfin to deduplicate and never update.
  - `?refresh=1` handler clears `/jellyfin-cache/xmltv/*.xml` before triggering Jellyfin task — stale cache had embedded PHP warnings breaking XML parse.
  - Fixed permissions: `chmod o+w /mnt/user/appdata/jellyfin/cache/xmltv/` so Apache www-data can delete cache files.
  - Added Jellyfin cache volume mount to `my-zuzz-proxy.xml`.
- **[2026-02-26] Zuzz-Proxy Hardened:** Restored WebUI link and enabled autostart via explicit labels and XML template.
- **[2026-02-26] Plane Project Management (LAB):**
  - Deployed Plane Community Edition stack (12 containers) via Docker Compose.
  - Network: Integrated into `icemulnet` with static IPs (172.18.0.20-32).
  - Visualization: Used "Stealth Helper" strategy (z- prefix, no icons) for database containers to keep the Unraid dashboard clean.
  - Main Entry: `Plane` container (proxy) configured with official icon and WebUI link (`http://[IP]:8083/`).
  - Integration: Created "Homelab Management" project (LAB) and migrated all pending tasks from `GEMINI.md`.
- **[2026-02-27] Plane SMTP Configuration:**
  - Configured SMTP via Gmail (`smtp.gmail.com:587`) for the Plane AIO container.
  - Patched `/app/plane.env` inside the container and updated `my-plane.xml` template for persistence.
  - Verified end-to-end delivery of test emails.
- **[2026-02-27] Plane Docker Panel Fixed (Session 8):**
  - Root cause: `net.unraid.docker.managed=true` — Unraid DockerClient.php requires the value `"dockerman"`. Corrected the label value in `my-plane.xml` ExtraParams.
  - Cleaned ~40 stale ghost entries from `/var/lib/docker/containers/*/docker.json` (leftover from iterative Plane stack rebuilds).
  - Plane now shows as a single managed icon with "up-to-date" status on the Unraid Docker dashboard.
- **[2026-02-27] Plane Auth Redirect Port Bug Fixed:**
  - Root cause: Upstream `start.sh` inside the AIO container constructs `WEB_URL` and `CORS_ALLOWED_ORIGINS` using `DOMAIN_NAME` only, with no port — causing OAuth/CSRF redirects to go to port 80 instead of 8083.
  - `DOMAIN_NAME` validation rejects `IP:port` values, so the fix was to patch `start.sh` with `APP_PORT` env var and `port_suffix` logic.
  - Patched `start.sh` bind-mounted into container at `/app/start.sh:ro` from `/mnt/user/appdata/plane/start.sh`.
  - Sign-in and sign-out now correctly redirect to `http://192.168.128.43:8083/`.
  - `plane-start.sh` (patched script) committed to repo. `my-plane.xml` updated with `APP_PORT` variable and volume mount for `start.sh`.
- **[2026-02-27] Plane LAB Project Restored:**
  - 47 issues created via Plane REST API. Workspace slug: "home", project: LAB.
  - States: 35 Done (completed ops history), 10 Todo (open pending tasks), 2 Cancelled.
  - API key stored at `C:\AI tools\secrets\plane_api.txt`.
- **[2026-02-27] Plane Automated Backup Configured:**
  - Script `plane_backup.sh` deployed to Unraid User Scripts and committed to repo.
  - Backs up: PostgreSQL dump (pg_dump custom format), MinIO Docker volume (tar.gz), Redis RDB, config files (`start.sh` + `my-plane.xml`).
  - Destination: `/mnt/user/backups/Unraid/plane_data/<date>/`. Log: `/boot/logs/plane-backup.log`.
  - 14-day retention. Daily schedule: 3:15 AM via `/etc/cron.d/root`.
  - Test run confirmed: 840K written successfully.

## Pending Critical Tasks (See Plane Board)
1. **[LAB-1] Implement off-server ZFS backup:** Sanoid+Syncoid → rsync.net or LAN backup host.
2. **[LAB-2] Configure Tailscale ACLs:** Exit node + no ACLs = full LAN exposure to all Tailnet peers.
3. **[LAB-3] Disable Tailscale key expiry** on Unraid node.
4. **[LAB-5] Audit binhex-delugevpn:** Verify kill switch active, LAN_NETWORK=192.168.128.0/24, WebUI not publicly exposed.

## Goals Met (as of 2026-02-27)
- [x] Rotate Plex Token (Completed 2026-02-24)
- [x] Establish secure remote management.
- [x] Optimize OS performance and power usage.
- [x] Resolve container update and crashing issues.
- [x] Implement ZFS data protection (Snapshots).
- [x] Audit storage for cleanup.
- [x] Library Optimization: Audited Radarr/Sonarr for duplicates and path alignment.
- [x] Source Optimization: Configured Radarr to prefer HEVC (x265) for storage efficiency.
- [x] Network Security: Implemented Cloudflare Access (Zero Trust) and Tailscale.
- [x] Application Migration: Successfully moved Mealie and Seerr to Unraid native Docker.
- [x] Service Restoration: Fixed a long-standing broken Wger installation.
- [x] Plex Template Repair: Restored corrupted my-plex.xml; mapped /transcode to /dev/shm.
- [x] Plex Hardware Acceleration: Enabled Intel QuickSync (iGPU) in Preferences.xml.
- [x] SMB Hardening: Restricted and hidden Flash drive SMB export via smb-extra.conf.
- [x] Arr Stack Synchronization: Added TZ=America/New_York to Radarr and Sonarr XML templates.
- [x] Docker Visibility: Installed Docker Compose Manager plugin for Compose stack GUI management.
- [x] Server Audit v2: Dual-agent re-audit produced server_audit_v2.md. Grade B+. 5 new findings.
- [x] Credentials Security: Added Preferences.xml to .gitignore to prevent token exposure in git.
- [x] **Plex Upload Rate Fixed:** 450000 → 4500 Kbps.
- [x] **Resource Constraints:** Added memory limits and healthchecks to Plex, Radarr, and Sonarr.
- [x] **Permissions Hardening:** Set UMASK=002 in Radarr and Sonarr templates.
- [x] **ZFS Script Repair:** Added error handling, health checks, and persistent logging to snapshot script.
- [x] **ZFS Properties Optimized:** Set xattr=sa, acltype=posixacl, dnodesize=auto, compression=lz4.
- [x] **Network Migration:** Migrated `icemulnet` to a `/24` subnet (`172.18.0.0/24`).
- [x] **Security Hardening:** Removed Prowlarr NPM proxy and added global security headers.
- [x] **ZFS Script v3:** Fixed critical pool health check bug. Script now runs correctly.
- [x] **Template Hardening v3:** Plex UMASK 002, --memory-swap on all containers, --health-start-period=30s, stale PLEX_CLAIM cleared.
- [x] **NPM Headers v3:** Removed deprecated X-XSS-Protection.
- [x] **Server Audit v3:** Grade upgraded to A-. 6 new findings all fixed in-session.
- [x] **Zuzz Proxy WebUI & Autostart:** Restored WebUI dropdown link via explicit labels and enabled container autostart.
- [x] **Plane Project Management:** Deployed full stack, migrated tasks, and cleaned up Unraid dashboard visualization.
- [x] **Plane Automation:** Admin + bot tokens stored, automation scripts/config created, labels/modules/Triage Queue applied to all projects, daily summaries scheduled at 01:00.
- [x] **Plane Docker Panel Fixed:** Corrected `net.unraid.docker.managed` label value to `"dockerman"`. Cleaned ~40 stale ghost container entries from docker.json.
- [x] **Plane Auth Redirect Fixed:** Patched `start.sh` with `APP_PORT`/`port_suffix` logic. Bind-mounted as volume. Sign-in/sign-out redirects now work correctly on port 8083.
- [x] **Plane LAB Issues Restored:** 47 issues (35 Done, 10 Todo, 2 Cancelled) created via Plane API.
- [x] **Plane Backup Automated:** `plane_backup.sh` deployed with pg_dump, MinIO, Redis, and config file backup. Daily 3:15 AM cron. 14-day retention. Test confirmed.

## Next Steps (Authoritative source: Plane [LAB])
- [CRITICAL] Implement off-server ZFS backup via Sanoid+Syncoid (Moved to Plane).
- [CRITICAL] Configure Tailscale ACLs (Moved to Plane).
- [HIGH] Disable Tailscale key expiry on Unraid node.
- [HIGH] Audit binhex-delugevpn: kill switch, LAN_NETWORK, WebUI.
- [HIGH] Audit/replace Seerr image (Overseerr migration).
- [MEDIUM] Replicate HEVC Custom Format to Sonarr via Recyclarr.
- [MEDIUM] Add Pi-hole secondary.
- [MEDIUM] ZFS: set compression=zstd and recordsize=16K.
- [MEDIUM] Add ZFS snapshot failure alerting.
- [MEDIUM] Configure HSTS at Cloudflare edge.
