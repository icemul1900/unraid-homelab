# GEMINI - Unraid Management State

This file defines the foundational mandates, architectural state, and operational history for Gemini agents managing the Unraid Homelab.

## Core Mandates
- **Single Source of Truth:** All technical findings, IP maps, and architectural decisions MUST be synchronized with `unraid_agent.md`.
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
- **Subnet:** 172.18.0.0/16
- **Gateway:** 172.18.0.1
- **Static Map:**
  - .3: prowlarr
  - .4: seerr
  - .5: NginxProxyManager (v25.09.1)
  - .6: sonarr
  - .9: radarr
  - .10: Mealie
  - .13: wger-web

## Recent Modifications & Fixes
- **[2026-02-20] Plex Template Repair:** Fixed corrupted `my-plex.xml` template. Restored GUI access and successfully mapped `/transcode` to `/dev/shm`.
- **[2026-02-20] Audit Synchronization:** Updated `server_audit.md` with verified mirror status, ARC limits, and NPM versioning.

## Pending Critical Tasks
1. **Wger Security:** Disable `ALLOW_REGISTRATION` in `/mnt/user/appdata/wger/docker-compose.yml`.
2. **SSH Hardening:** Disable password authentication in `/boot/config/go`.
3. **Backup Strategy:** Implement off-server ZFS snapshot replication.
4. **Environment Consistency:** Inject `TZ` variables into Radarr and Sonarr templates.

## Goals Met (as of 2026-02-20)
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

## Next Steps (as of 2026-02-20)
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

## Session Log
- [2026-02-20] Plex template repaired (my-plex.xml). /transcode mapped to /dev/shm.
- [2026-02-20] server_audit.md created. ZFS mirror verified, ARC at 8GB, NPM v25.09.1 confirmed safe.
- [2026-02-20] GEMINI.md initialized as multi-agent architectural state file. icemulnet IP map and pending tasks documented.
