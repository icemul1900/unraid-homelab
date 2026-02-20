# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

This is an Unraid home server configuration and operations journal. It contains Docker container templates, maintenance scripts, and a running log of server changes.

## Server Details

- **Host:** 192.168.128.43 (Unraid 7.2.3)
- **Hardware:** Intel i5-10505 (6C/12T), 64GB RAM
- **Storage:** 15TB array + 1TB ZFS cache pool (`apps`)
- **ZFS datasets:** `apps/appdata`, `apps/system`

## Architecture & Conventions

### Docker Templates (`.xml` files)
These are Unraid Community Applications templates. Key conventions:
- All containers use the custom bridge network `icemulnet`
- Standard PUID/PGID is `99`/`100` (Unraid's `nobody`/`users`)
- Appdata is stored at `/mnt/user/appdata/<container-name>`
- Both Radarr and Sonarr map host path `/mnt/user/plex/` to container path `/data` — this unified path is required for atomic moves and hardlink support across the *arr stack

### ZFS Snapshot Script (`zfs_snapshot.sh`)
- Targets datasets `apps/appdata` and `apps/system`
- Creates daily snapshots named `daily-YYYY-MM-DD`
- Retains the 7 most recent snapshots and destroys older ones
- Deployed as a User Scripts cron job on the Unraid host

### Network Security Layers
- **Cloudflare Zero Trust:** Protects external subdomains (`meals`, `request`, `workout`, `bridgman`) with email + 6-digit PIN. Home public IP has a bypass policy.
- **Tailscale:** Mesh VPN for family device access to Home Assistant and Unraid GUI; Unraid node configured as an exit node.
- **Pi-hole DNS:** Split-brain DNS is avoided — local A records for Cloudflare Tunnel hostnames are removed so all devices resolve through the Cloudflare edge.

### Running Services
| Service | Port | Notes |
|---------|------|-------|
| Radarr | 7878 | Prefers HEVC/x265 (CF score 500); 1080p quality: 5–35 MB/min |
| Sonarr | 8989 | |
| Mealie | — | Migrated from Hyper-V; NPM proxy + SMTP port 587/TLS |
| Seerr | — | `ghcr.io/seerr-team/seerr`; custom XML template in this repo |
| Wger | — | Compose stack: web + PostgreSQL + Redis + Nginx sidecar |

## Ongoing Notes (`unraid_agent.md`)
This file serves as the persistent ops log. When making changes to the server, append dated entries under `## Logs & Findings` and update `## Goals Met` / `## Next Steps` accordingly.

## Goals Met
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
- [x] Plex Hardware Acceleration: Enabled Intel QuickSync (iGPU) in Preferences.xml and verified template mapping.
- [x] SMB Hardening: Restricted and hidden Flash drive SMB export via smb-extra.conf.
- [x] Arr Stack Synchronization: Added TZ=America/New_York to Radarr and Sonarr XML templates.
- [x] Docker Visibility: Installed Docker Compose Manager plugin for Compose stack GUI management.
- [x] Server Audit v2: Dual-agent re-audit produced server_audit_v2.md. Grade B+. 5 new critical/high findings.
- [x] Credentials Security: Added Preferences.xml to .gitignore to prevent Plex token from entering git history.
- [x] Agent Context Initialization: Created GEMINI.md as the multi-agent state file.

## Next Steps
- [CRITICAL] Rotate Plex token: sign out and back in on the server to invalidate the credential exposed before gitignore was added.
- [CRITICAL] Fix ZFS snapshot script: add exit-code check, pool health gate, existence check for same-day re-runs, and persistent logging to /boot/logs/zfs-snapshot.log.
- [CRITICAL] Implement off-server ZFS backup via Sanoid+Syncoid (3 sessions overdue).
- [CRITICAL] Configure Tailscale ACLs: exit node + no ACLs = full LAN exposure. ACL policy in server_audit_v2.md C4.
- [USER BYPASS] Wger open registration: user opted to keep ALLOW_REGISTRATION=True.
- [USER BYPASS] SSH hardening: user keeping password auth as safety fallback.
- [HIGH] Fix Plex WanTotalMaxUploadRate: 450000 Kbps (450 Mbps) → 4500 Kbps in Plex Settings → Remote Access.
- [HIGH] Migrate icemulnet to /24: currently /16, collision risk with Docker subnet pool.
- [HIGH] Change UMASK 022 → 002 in my-radarr.xml and my-sonarr.xml.
- [HIGH] Remove/restrict Prowlarr NPM proxy entry (internal-only service, no external auth).
- [HIGH] Disable Tailscale key expiry on Unraid node.
- [MEDIUM] Set ZFS properties: xattr=sa acltype=posixacl dnodesize=auto compression=lz4 on both datasets.
- [MEDIUM] Add healthchecks to Radarr + Sonarr ExtraParams (curl /ping).
- [MEDIUM] Add container memory limits to templates (Radarr/Sonarr 1g, Plex 4g, etc.).
- [MEDIUM] Replicate HEVC Custom Format to Sonarr via Recyclarr.
- [MEDIUM] Add security headers in NPM Advanced tab (HSTS, X-Frame-Options, X-Content-Type-Options).
- [MEDIUM] Add Pi-hole secondary container + Gravity Sync for DNS failover.
- [LOW] Verify Plex remote access (Tailscale preferred over port forwarding/relay).
- [LOW] Verify Wger CSRF_TRUSTED_ORIGINS is still correctly set.
- [LOW] Audit Seerr image provenance (third-party fork ghcr.io/seerr-team/seerr holds API keys).
- [LOW] Consider increasing ZFS ARC to 16-24GB on 64GB system.

## Logs & Findings
- [2026-02-20] Plex template repaired (my-plex.xml). /transcode mapped to /dev/shm.
- [2026-02-20] server_audit.md created. ZFS mirror verified, ARC at 8GB, NPM v25.09.1 confirmed safe.
- [2026-02-20] GEMINI.md created as multi-agent architectural state file. icemulnet IP map and pending tasks documented.
- [2026-02-20] Session 2: Dual-agent re-audit completed. server_audit_v2.md produced. Grade revised B+ (was A-). New critical findings: Plex token in Preferences.xml in git, ZFS snapshot script logic bugs (4 confirmed), WanTotalMaxUploadRate=450000 (100x wrong), icemulnet /16 subnet misconfiguration, UMASK=022. Tailscale ACLs escalated to CRITICAL. Preferences.xml added to .gitignore.
