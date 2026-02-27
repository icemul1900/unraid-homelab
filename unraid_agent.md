# Unraid Agent Log

## Server Information
- **IP Address:** 192.168.128.43
- **OS Version:** Unraid 7.2.3
- **CPU:** Intel(R) Core(TM) i5-10505 (6C/12T)
- **RAM:** 64GB
- **Storage:** 15TB Array + 1TB ZFS Cache (apps pool)

## Goals Met
- [x] **Server Audit v2:** Dual-agent re-audit produced `server_audit_v2.md`. Grade revised to B+.
- [x] Establish secure remote management.
- [x] Optimize OS performance and power usage.
- [x] Resolve container update and crashing issues.
- [x] Implement ZFS data protection (Snapshots).
- [x] Audit storage for cleanup.
- [x] **Library Optimization:** Audited Radarr/Sonarr for duplicates and path alignment.
- [x] **Source Optimization:** Configured Radarr to prefer HEVC (x265) for storage efficiency.
- [x] **Network Security:** Implemented Cloudflare Access (Zero Trust) and Tailscale.
- [x] **Application Migration:** Successfully moved Mealie and Seerr to Unraid native Docker.
- [x] **Service Restoration:** Fixed a long-standing broken Wger installation.
- [x] **Plex Template Repair:** Restored corrupted `my-plex.xml`.
- [x] **Server Audit:** Produced comprehensive `server_audit.md`. Grade bumped to **A-**.
- [x] **Agent Context Initialization:** Created `GEMINI.md` as the authoritative multi-agent state file.
- [x] **Plex Hardware Acceleration:** Enabled Intel QuickSync (iGPU).
- [x] **SMB Hardening:** Restricted and hidden the Unraid Flash drive SMB export.
- [x] **Arr Stack Synchronization:** Added `TZ=America/New_York` and verified container environments.
- [x] **Network Migration:** Migrated `icemulnet` to a `/24` subnet (`172.18.0.0/24`).
- [x] **Security Hardening:** Removed Prowlarr NPM proxy and added global security headers.
- [x] **Plex Upload Rate:** Fixed `WanTotalMaxUploadRate` (4500 Kbps).
- [x] **Resource Limits:** Added memory limits and healthchecks to templates.
- [x] **Permissions:** Tightened `UMASK` to `002` for Radarr and Sonarr.
- [x] **ZFS Protection:** Improved `zfs_snapshot.sh` with exit-code checks and logging.
- [x] **ZFS Optimization:** Set `xattr=sa acltype=posixacl dnodesize=auto compression=lz4`.
- [x] **Docker Visibility:** Installed Docker Compose Manager plugin.
- [x] **Plex Token Rotation:** Rotated Plex token after exposure.
- [x] **ZFS Script v3:** Fixed critical pool health check bug.
- [x] **Plex Template Hardening:** Fixed UMASK, cleared stale PLEX_CLAIM, added --memory-swap.
- [x] **Arr Stack Template Hardening:** Added --memory-swap and --health-start-period.
- [x] **NPM Headers:** Removed deprecated `X-XSS-Protection`.
- [x] **Server Audit v3:** Grade upgraded to A-. 6 new findings identified and fixed.
- [x] **Library Cleanup:** Resolved Plex matching conflict for 'The Last Frontier'.
- [x] **Permissions Repair:** Fixed SMB access to `/mnt/user/plex/tv/`.
- [x] **Zuzz Stream Proxy:** Deployed `zuzz-proxy` PHP/Apache container. Full Jellyfin Live TV guide integration working end-to-end.
- [x] **Zuzz Proxy Hardened:** Restored WebUI dropdown link via explicit labels and enabled container autostart.
- [x] **Plane Project Management:** Deployed full Plane Community stack. Integrated tasks into "Homelab Management" project.
- [x] **Plane Automation:** Plane admin configured, bot verified, projects created for all `C:\AI tools\Home` folders, labels/modules + Triage Queue applied, automation scripts deployed, daily summaries scheduled at 01:00.
- [x] **Plane Docker Panel Fixed:** Corrected `net.unraid.docker.managed` label value (`true` → `dockerman`). Cleaned ~40 ghost entries from docker.json. Plane shows as single managed icon with up-to-date status.
- [x] **Plane Auth Redirect Fixed:** Patched `start.sh` with `APP_PORT`/`port_suffix` logic; bind-mounted from host at `/mnt/user/appdata/plane/start.sh`. Sign-in/sign-out redirects now correctly target port 8083.
- [x] **Plane LAB Issues Restored:** 47 issues created via Plane REST API (35 Done, 10 Todo, 2 Cancelled).
- [x] **Plane Backup Automated:** `plane_backup.sh` deployed to User Scripts. Backs up PostgreSQL, MinIO, Redis, and config files daily at 3:15 AM to `/mnt/user/backups/Unraid/plane_data/`. 14-day retention. Test confirmed (840K written).

## Logs & Findings
- [2026-02-13] **ZFS Protection:** Deployed rotation script and ZFS Master Plugin.
- [2026-02-13] **Hardlinks (Arr Stack):** Verified unified paths under `/data`. Atomic moves confirmed.
- [2026-02-20] **Docker Storage Cleanup:** Reclaimed 9.5GB by pruning unused images/containers.
- [2026-02-24] **Server Audit v3:** Grade upgraded to A-. 6 new findings all fixed in-session. Two CRITICALs (off-server backup, Tailscale ACLs) remain unaddressed for 5 sessions.
- [2026-02-26] **Zuzz Stream Proxy (guide fully working):** Root cause chain for guide never updating identified and fixed. Guide is now confirmed working: 5 channels, 5 programmes showing correct stream event names.
- [2026-02-26] **Zuzz-Proxy Fixes:** Restored missing WebUI link by recreating the container with explicit `net.unraid.docker.webui` and `net.unraid.docker.icon` labels. Enabled autostart with `--restart unless-stopped`.
- [2026-02-26] **Plane Deployment:** Migrated Plane stack to `icemulnet` with static IPs (172.18.0.20-32). Fixed startup crashes (Gunicorn workers) and cleaned up Unraid dashboard by grouping containers and using "stealth" naming for helper services.
- [2026-02-27] **Plane Automation:** Admin + bot tokens stored, automation scripts/config created, labels/modules/Triage Queue applied to all projects, daily summaries scheduled at 01:00.
- [2026-02-27] **Plane Docker Panel Fixed (Session 8):** Root cause was `net.unraid.docker.managed=true` — value must be `"dockerman"` for DockerClient.php. Fixed ExtraParams label in `my-plane.xml`. Cleaned ~40 stale ghost entries from docker.json. Single managed icon confirmed.
- [2026-02-27] **Plane Auth Redirect Port Bug Fixed:** Upstream `start.sh` omits port from WEB_URL/CORS. DOMAIN_NAME validator rejects IP:port. Fix: patched `start.sh` with `APP_PORT` env var and `port_suffix` variable. Bind-mounted `/mnt/user/appdata/plane/start.sh` → `/app/start.sh:ro`. `my-plane.xml` updated with `APP_PORT=8083` config variable. Auth redirects now correct.
- [2026-02-27] **Plane LAB Issues Restored via API:** 47 issues (35 Done, 10 Todo, 2 Cancelled). Workspace: "home", project: LAB. API key at `C:\AI tools\secrets\plane_api.txt`.
- [2026-02-27] **Plane Automated Backup Deployed:** `plane_backup.sh` in User Scripts. pg_dump (custom format), MinIO tar.gz, Redis RDB, config files. Dest: `/mnt/user/backups/Unraid/plane_data/`. Log: `/boot/logs/plane-backup.log`. 14-day retention, 3:15 AM daily. Test run: 840K OK.

## Next Steps
- **[CRITICAL] Implement off-server backup:** Sanoid+Syncoid → rsync.net or LAN backup host. 5 sessions overdue.
- **[CRITICAL] Configure Tailscale ACLs:** Escalated. Exit node + no ACLs = full LAN exposure.
- **[HIGH] Disable Tailscale key expiry** on Unraid node.
- **[HIGH] Verify binhex-delugevpn:** Kill switch, LAN_NETWORK setting, WebUI exposure.
- **[HIGH] Audit/replace Seerr image:** ghcr.io/seerr-team/seerr is a third-party fork holding API keys.
- **[MEDIUM] Replicate HEVC Custom Format to Sonarr** via Recyclarr.
- **[MEDIUM] Add Pi-hole secondary** (second container on icemulnet).
- **[MEDIUM] ZFS: set compression=zstd and recordsize=16K** on apps/appdata.
- **[MEDIUM] Add ZFS snapshot failure alerting** (healthchecks.io or Unraid notify).
- **[MEDIUM] Configure HSTS at Cloudflare edge** for CF-proxied subdomains.
