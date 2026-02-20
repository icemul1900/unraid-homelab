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
- [x] Server Audit: Produced server_audit.md grading all subsystems. Overall grade: B.
- [x] Agent Context Initialization: Created GEMINI.md as the multi-agent state file.

## Next Steps
- [CRITICAL] Disable Wger open registration: Set ALLOW_REGISTRATION=False in /mnt/user/appdata/wger/docker-compose.yml.
- [CRITICAL] Implement off-server ZFS snapshot replication for apps/appdata.
- [HIGH] Verify Plex Hardware Transcoding is enabled in Plex Settings → Transcoder.
- [HIGH] Harden SSH: Disable password auth in /boot/config/go.
- [HIGH] Restrict Flash Drive SMB Export to private.
- [HIGH] Add Tailscale ACLs; disable key expiry on Unraid node.
- [HIGH] Add TZ variable to my-radarr.xml and my-sonarr.xml.
- [HIGH] Install Docker Compose Manager plugin for Wger GUI visibility.
- [MEDIUM] Replicate HEVC Custom Format to Sonarr v4.
- [MEDIUM] Add security headers in NPM Advanced tab.
- [MEDIUM] Add Pi-hole DNS failover via DHCP secondary.
- [MEDIUM] Add container memory limits to templates.

## Logs & Findings
- [2026-02-20] Plex template repaired (my-plex.xml). /transcode mapped to /dev/shm.
- [2026-02-20] server_audit.md created. ZFS mirror verified, ARC at 8GB, NPM v25.09.1 confirmed safe.
- [2026-02-20] GEMINI.md created as multi-agent architectural state file. icemulnet IP map and pending tasks documented.
