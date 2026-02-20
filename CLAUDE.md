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
