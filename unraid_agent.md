# Unraid Agent Log

## Server Information
- **IP Address:** 192.168.128.43
- **OS Version:** Unraid 7.2.3
- **CPU:** Intel(R) Core(TM) i5-10505 (6C/12T)
- **RAM:** 64GB
- **Storage:** 15TB Array + 1TB ZFS Cache (apps pool)

## Goals Met
- [x] **Server Audit v2:** Dual-agent re-audit (homelab expert + Gemini researcher) produced `server_audit_v2.md`. Grade revised to B+ (down from A-). 5 new findings identified.
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
- [x] **Plex Template Repair:** Restored corrupted `my-plex.xml`; mapped `/transcode` to `/dev/shm` for RAM-based transcoding.
- [x] **Server Audit:** Produced comprehensive `server_audit.md` grading all subsystems. Grade bumped to **A-** after session fixes.
- [x] **Agent Context Initialization:** Created `GEMINI.md` as the authoritative multi-agent state file.
- [x] **Plex Hardware Acceleration:** Enabled Intel QuickSync (iGPU) in `Preferences.xml` and verified template mapping.
- [x] **SMB Hardening:** Restricted and hidden the Unraid Flash drive SMB export via `smb-extra.conf`.
- [x] **Arr Stack Synchronization:** Added `TZ=America/New_York` to Radarr and Sonarr XML templates and verified container environments.
- [x] **Docker Visibility:** Installed Docker Compose Manager plugin for GUI management of Compose stacks.

## Logs & Findings
- [2026-02-13] **ZFS Protection:** Deployed rotation script and ZFS Master Plugin.
- [2026-02-13] **Hardlinks (Arr Stack):** Verified unified paths under `/data` for Sonarr and Radarr. Atomic moves confirmed working.
- [2026-02-16] **Radarr Library Audit:** Imported 200+ movies; removed duplicates and reclaimed space.
- [2026-02-18] **Wger Workout Manager:** Deployed Docker Compose stack; fixed static files and CSRF.
- [2026-02-20] **Docker Storage Cleanup:** Reclaimed 9.5GB by pruning unused images/containers after a full `docker.img` caused a failed Huly installation attempt.
- [2026-02-20] **Huly Cleanup:** Attempted Huly self-hosted installation; encountered CockroachDB auth and Elasticsearch resource issues. Successfully removed all trace containers, networks, and images to return to clean state.
- [2026-02-20] **Plex Performance:** Verified `/dev/dri/renderD128` availability and permissions. Enabled `HardwareAcceleratedCodecs` and `HardwareAcceleratedEncoding` in `Preferences.xml`.
- [2026-02-20] **Arr stack TZ fix:** Updated `my-radarr.xml` and `my-sonarr.xml` in `/boot/config/plugins/dockerMan/templates-user/`. Restarted containers to apply EST timezone.
- [2026-02-20] **Flash SMB Security:** Modified `smb-extra.conf` to set `[flash]` share to `browseable = no` and `public = no`. Reloaded Samba.
- [2026-02-20] **Server Audit v2:** Dual-agent re-audit completed. Grade revised B+ (was A-). 5 new critical/high findings: Plex token in git, ZFS snapshot script logic bug, WanTotalMaxUploadRate 100× wrong (450 Mbps), icemulnet /16 subnet, UMASK=022. Report saved to `server_audit_v2.md`.

## Next Steps
- **[USER BYPASS] Wger open registration:** User requested to keep registration active for others.
- **[ON HOLD] Harden SSH:** User opting to keep password auth enabled as a safety backup to SSH keys.
- **[CRITICAL] Add Preferences.xml to .gitignore + rotate Plex token.** Live auth token found in git repo. *** NEW ***
- **[CRITICAL] Fix ZFS snapshot script:** No exit-code check, `2>/dev/null` masks errors, no pool health gate, no logging. *** NEW ***
- **[CRITICAL] Implement off-server backup:** Sanoid+Syncoid → rsync.net or LAN backup host. 3 sessions overdue.
- **[CRITICAL] Configure Tailscale ACLs:** Escalated. Exit node + no ACLs = full LAN exposure. See ACL policy in server_audit_v2.md.
- **[HIGH] Fix Plex WanTotalMaxUploadRate:** Currently `450000` (450 Mbps). Should be `4500` for ~4.5 Mbps cap. *** NEW ***
- **[HIGH] Migrate icemulnet to /24:** Current /16 risks Docker subnet collisions. *** NEW ***
- **[HIGH] Change UMASK 022 → 002** in Radarr + Sonarr templates. *** NEW ***
- **[HIGH] Remove/restrict Prowlarr NPM proxy entry.** No auth layer; should be internal-only. *** NEW ***
- **[HIGH] Disable Tailscale key expiry** on Unraid node.
- **[MEDIUM] Set ZFS properties:** `xattr=sa acltype=posixacl dnodesize=auto compression=lz4` on both datasets.
- **[MEDIUM] Add healthchecks** to Radarr + Sonarr ExtraParams. *** NEW ***
- **[MEDIUM] Add container memory limits** to templates (Radarr/Sonarr 1g, Plex 4g).
- **[MEDIUM] Replicate HEVC Custom Format to Sonarr** via Recyclarr.
- **[MEDIUM] Add security headers** in NPM Advanced tab.
- **[MEDIUM] Add Pi-hole secondary** (second container on icemulnet + Gravity Sync).
- **[LOW] Verify Plex remote access** — use Tailscale over port forwarding/relay.
- **[LOW] Verify Wger CSRF_TRUSTED_ORIGINS** still set correctly.
- **[LOW] Audit Seerr image provenance** (third-party fork holds API keys).
