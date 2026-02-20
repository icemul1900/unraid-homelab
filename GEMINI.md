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
- **[2026-02-20] Server Audit v2:** Dual-agent re-audit (homelab expert + Gemini researcher) produced `server_audit_v2.md`. Grade revised B+ (was A-). 5 new critical/high findings identified.
- **[2026-02-20] Credentials Security:** Added `Preferences.xml` to `.gitignore`. File contains live Plex auth token — must never be committed.

## Pending Critical Tasks
1. **[CRITICAL] Rotate Plex Token:** Sign out and back in on the Plex server to invalidate the exposed token. Preferences.xml is now gitignored.
2. **[CRITICAL] Fix ZFS snapshot script:** Add exit-code check, pool health gate, existence check for same-day re-runs, and persistent logging to `/boot/logs/zfs-snapshot.log`. Replace long-term with Sanoid+Syncoid.
3. **[CRITICAL] Implement off-server ZFS backup:** Sanoid+Syncoid → rsync.net or LAN backup host. 3 sessions overdue.
4. **[CRITICAL] Configure Tailscale ACLs:** Exit node + no ACLs = full LAN exposure to all Tailnet peers. ACL policy documented in `server_audit_v2.md` C4.
5. **[HIGH] Fix Plex WanTotalMaxUploadRate:** `450000` (450 Mbps) → `4500` (4.5 Mbps) in Plex Settings → Remote Access.
6. **[HIGH] Migrate icemulnet to /24:** Recreate as `172.18.0.0/24`; all existing static IPs are valid.
7. **[HIGH] Change UMASK 022 → 002** in `my-radarr.xml` and `my-sonarr.xml`.
8. **[HIGH] Remove/restrict Prowlarr NPM proxy entry:** Prowlarr is internal-only; no external proxy needed.
9. **[HIGH] Disable Tailscale key expiry** on Unraid node.

## Goals Met (as of 2026-02-20, Session 2)
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

## Next Steps (as of 2026-02-20, Session 2)
- [CRITICAL] Rotate Plex token: sign out and back in on the server to invalidate the exposed credential.
- [CRITICAL] Fix ZFS snapshot script: exit-code check, pool health gate, existence check, persistent logging.
- [CRITICAL] Implement off-server ZFS backup via Sanoid+Syncoid (3 sessions overdue).
- [CRITICAL] Configure Tailscale ACLs (exit node + no ACLs = full LAN exposure). See server_audit_v2.md C4.
- [HIGH] Fix Plex WanTotalMaxUploadRate: 450000 (Kbps) → 4500 Kbps.
- [HIGH] Migrate icemulnet to /24 (currently /16, collision risk).
- [HIGH] Change UMASK 022 → 002 in Radarr + Sonarr templates.
- [HIGH] Remove/restrict Prowlarr NPM proxy entry (internal-only service).
- [HIGH] Disable Tailscale key expiry on Unraid node.
- [MEDIUM] Set ZFS properties: xattr=sa acltype=posixacl dnodesize=auto compression=lz4 on both datasets.
- [MEDIUM] Add healthchecks to Radarr + Sonarr ExtraParams.
- [MEDIUM] Add container memory limits to templates.
- [MEDIUM] Replicate HEVC Custom Format to Sonarr via Recyclarr.
- [MEDIUM] Add security headers in NPM Advanced tab.
- [MEDIUM] Add Pi-hole secondary (second container + Gravity Sync).
- [LOW] Verify Plex remote access (Tailscale preferred over port forwarding/relay).
- [LOW] Verify Wger CSRF_TRUSTED_ORIGINS still correct.
- [LOW] Audit Seerr image provenance (third-party fork holds API keys).
- [LOW] Consider increasing ZFS ARC to 16-24GB.

## Session Log
- [2026-02-20] Plex template repaired (my-plex.xml). /transcode mapped to /dev/shm.
- [2026-02-20] server_audit.md created. ZFS mirror verified, ARC at 8GB, NPM v25.09.1 confirmed safe.
- [2026-02-20] GEMINI.md initialized as multi-agent architectural state file. icemulnet IP map and pending tasks documented.
- [2026-02-20] Session 2: Dual-agent re-audit completed. server_audit_v2.md produced. Grade revised B+ (was A-). 5 new critical/high findings: Plex token in git, ZFS script logic bug, WanTotalMaxUploadRate 100x wrong, icemulnet /16, UMASK=022. Preferences.xml added to .gitignore.
