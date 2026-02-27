# agents.md — Unraid Homelab Multi-Agent State

This file is the shared context document for all AI agents (Claude, Gemini, or otherwise) working on this Unraid homelab project. It mirrors the operational state of `unraid_agent.md` and `GEMINI.md` and must remain in sync with both.

## Project Scope

Unraid home server at `192.168.128.43` (Unraid 7.2.3). Docker-based media/automation stack on a custom bridge network (`icemulnet`). ZFS cache pool (`apps`) for appdata. Cloudflare Zero Trust + Tailscale for network security.

## Core Conventions for Agents

- **SSH target:** `192.168.128.43` (root, key-based auth)
- **Appdata path:** `/mnt/user/appdata/<container-name>`
- **Media path:** `/mnt/user/plex/` (mapped to `/data` in arr containers)
- **XML templates:** On host at `/boot/config/plugins/dockerMan/templates-user/`
- **All containers:** `icemulnet` bridge network, `PUID=99 / PGID=100`
- **Never commit `Preferences.xml`** — contains live Plex auth token. File is gitignored.

## Network Registry (icemulnet — 172.18.0.0/24)

| IP | Container |
|----|-----------|
| 172.18.0.3 | prowlarr |
| 172.18.0.4 | seerr |
| 172.18.0.5 | NginxProxyManager (v25.09.1) |
| 172.18.0.6 | sonarr |
| 172.18.0.9 | radarr |
| 172.18.0.10 | mealie |
| 172.18.0.13 | wger-web |

## Goals Met (as of 2026-02-23)

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
- [x] Server Audit v2: Dual-agent re-audit produced server_audit_v2.md. Grade B+. 5 new critical/high findings.
- [x] Credentials Security: Added Preferences.xml to .gitignore to prevent Plex token from entering git history.
- [x] **Plex Configuration Fixed:** Upload rate (450000 → 4500), memory limit (4g), and healthcheck added.
- [x] **Arr Stack Hardening:** Memory limits (1g), healthchecks, and UMASK (002) added to Radarr/Sonarr.
- [x] **ZFS Protection:** Corrected `zfs_snapshot.sh` with exit codes, health gate, and logging.
- [x] **ZFS Optimization:** Set `xattr=sa acltype=posixacl dnodesize=auto compression=lz4` on both datasets.
- [x] **Network Migration:** Migrated `icemulnet` to a `/24` subnet (`172.18.0.0/24`) to avoid collisions.
- [x] **NPM Hardening:** Removed Prowlarr proxy and added global security headers (HSTS, X-Frame-Options).
- [x] **Plex Token Rotation:** Rotated Plex token after exposure (Verified 2026-02-24).
- [x] **ZFS Script v3:** Fixed critical pool health check bug (`zpool status -x` with no arg). Added `mkdir -p /boot/logs`. Script now runs correctly on every cron invocation.
- [x] **Template Hardening v3:** Plex UMASK 002 (was 022), --memory-swap enforced on all containers, --health-start-period=30s added, stale PLEX_CLAIM cleared.
- [x] **NPM Headers v3:** Removed deprecated X-XSS-Protection from npm_http.conf.
- [x] **Server Audit v3:** Dual-agent re-audit. Grade A- (up from B+). 6 new findings identified and all fixed in-session. Report in server_audit_v3.md.
- [x] **Plane Automation:** Plane admin configured, bot verified, projects created for all `C:\AI tools\Home` folders, labels/modules + Triage Queue applied, automation scripts deployed, daily summaries scheduled at 01:00.
- [x] **Plane Docker Panel Fixed:** Corrected `net.unraid.docker.managed` label value (`true` → `dockerman`). Cleaned ~40 stale ghost container entries from docker.json. Plane shows as single managed icon.
- [x] **Plane Auth Redirect Fixed:** Patched `start.sh` with `APP_PORT`/`port_suffix` logic; bind-mounted from `/mnt/user/appdata/plane/start.sh`. Auth redirects now target port 8083 correctly.
- [x] **Plane LAB Issues Restored:** 47 issues created via Plane REST API (35 Done, 10 Todo, 2 Cancelled). Workspace: "home".
- [x] **Plane Backup Automated:** `plane_backup.sh` deployed. pg_dump, MinIO, Redis, config files. Daily 3:15 AM, 14-day retention, `/mnt/user/backups/Unraid/plane_data/`. Test confirmed.

## Next Steps (as of 2026-02-27)

- [CRITICAL] Implement off-server ZFS backup via Sanoid+Syncoid (4 sessions overdue). See server_audit_v3.md C1.
- [CRITICAL] Configure Tailscale ACLs: exit node + no ACLs = full LAN exposure. Updated draft policy in server_audit_v3.md C2.
- [USER BYPASS] Wger open registration: user opted to keep ALLOW_REGISTRATION=True.
- [USER BYPASS] SSH hardening: user keeping password auth as safety fallback.
- [HIGH] Disable Tailscale key expiry on Unraid node.
- [HIGH] Audit binhex-delugevpn: verify kill switch active, LAN_NETWORK=192.168.128.0/24, WebUI not publicly exposed.
- [HIGH] Audit/replace Seerr image (ghcr.io/seerr-team/seerr holds Plex/Radarr/Sonarr API keys).
- [MEDIUM] Replicate HEVC Custom Format to Sonarr via Recyclarr.
- [MEDIUM] Add Pi-hole secondary container + DNS failover (verify Gravity Sync/Pi-hole v6 compat first).
- [MEDIUM] ZFS: set compression=zstd and recordsize=16K on apps/appdata.
- [MEDIUM] Add ZFS snapshot failure alerting (healthchecks.io or Unraid notify).
- [MEDIUM] Configure HSTS at Cloudflare edge for CF-proxied subdomains.
- [LOW] Verify Plex remote access (Tailscale preferred over port forwarding/relay).
- [LOW] Verify Wger CSRF_TRUSTED_ORIGINS is still correctly set.
- [LOW] Consider increasing ZFS ARC to 16-24GB on 64GB system.
- [LOW] Consider increasing Plex memory cap to 6-8g.

## Session Log

- [2026-02-20] Session 1: Plex template repaired. server_audit.md created (grade B). GEMINI.md initialized.
- [2026-02-20] Session 2: Dual-agent re-audit completed. server_audit_v2.md produced. Grade revised B+ (was A-). 5 new critical/high findings: Plex token in git, ZFS script logic bugs, WanTotalMaxUploadRate 100x wrong, icemulnet /16, UMASK=022. Tailscale ACLs escalated to CRITICAL. Preferences.xml added to .gitignore.
- [2026-02-23] Session 3: Fixed Plex upload rate, memory limits, and healthchecks. Hardened Radarr/Sonarr (UMASK 002, memory limits, healthchecks). Improved ZFS snapshot script. Optimized ZFS dataset properties. Migrated `icemulnet` to `/24`. Removed Prowlarr NPM proxy. Added global security headers to NPM.
- [2026-02-24] Session 4: Verified Plex token rotation. Server audit v3 completed (dual-agent). Grade A- (up from B+). 6 new findings all fixed in-session: ZFS pool health check bug (script was aborting every run since v2), Plex UMASK 022→002, --memory-swap added to all containers, --health-start-period=30s added, X-XSS-Protection removed, stale PLEX_CLAIM cleared. New open findings: delugevpn (HIGH), Seerr provenance (HIGH), ZFS recordsize+zstd (MEDIUM), snapshot alerting (MEDIUM), CF HSTS (MEDIUM).

- [2026-02-27] Session 7: Plane finalized. Admin + bot tokens stored, automation scripts/config created, labels/modules/Triage Queue applied to all projects, daily summaries scheduled at 01:00.
- [2026-02-27] Session 8: Plane Docker panel fixed (managed label), auth redirect port bug fixed (start.sh patch + bind mount), LAB project restored with 47 issues via API, automated backup script deployed and tested.
