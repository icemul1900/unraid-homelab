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

## Network Registry (icemulnet — 172.18.0.0/16, migrate to /24)

| IP | Container |
|----|-----------|
| 172.18.0.3 | prowlarr |
| 172.18.0.4 | seerr |
| 172.18.0.5 | NginxProxyManager (v25.09.1) |
| 172.18.0.6 | sonarr |
| 172.18.0.9 | radarr |
| 172.18.0.10 | mealie |
| 172.18.0.13 | wger-web |

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
- [x] Server Audit v2: Dual-agent re-audit produced server_audit_v2.md. Grade B+. 5 new critical/high findings.
- [x] Credentials Security: Added Preferences.xml to .gitignore to prevent Plex token from entering git history.

## Next Steps (as of 2026-02-20, Session 2)

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

## Session Log

- [2026-02-20] Session 1: Plex template repaired. server_audit.md created (grade B). GEMINI.md initialized.
- [2026-02-20] Session 2: Dual-agent re-audit completed. server_audit_v2.md produced. Grade revised B+ (was A-). 5 new critical/high findings: Plex token in git, ZFS script logic bugs, WanTotalMaxUploadRate 100x wrong, icemulnet /16, UMASK=022. Tailscale ACLs escalated to CRITICAL. Preferences.xml added to .gitignore.
