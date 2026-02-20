# Unraid Agent Log

## Server Information
- **IP Address:** 192.168.128.43
- **OS Version:** Unraid 7.2.3
- **CPU:** Intel(R) Core(TM) i5-10505 (6C/12T)
- **RAM:** 64GB
- **Storage:** 15TB Array + 1TB ZFS Cache (apps pool)

## Goals Met
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
- [x] **Server Audit:** Produced comprehensive `server_audit.md` grading all subsystems (Security, Storage, Performance, Docker, Networking). Verified ZFS mirror status, ARC cap, and NPM version.
- [x] **Agent Context Initialization:** Created `GEMINI.md` as the authoritative multi-agent state file with architectural snapshot and pending task registry.

## Logs & Findings
- [2026-02-13] **ZFS Protection:** Deployed rotation script and ZFS Master Plugin.
- [2026-02-13] **Hardlinks (Arr Stack):** Verified unified paths under `/data` for Sonarr and Radarr. Atomic moves confirmed working.
- [2026-02-16] **Radarr Library Audit:** 
    - Imported 200+ movies into Radarr to enable active management.
    - Identified and removed multiple `sync-conflict` files and unmapped duplicates to reclaim space.
- [2026-02-16] **Storage & Quality Tuning:**
    - Configured Radarr Quality Definitions for 1080p: Min 5MB/min, Preferred 20MB/min, Max 35MB/min.
    - Set a "hard ceiling" to keep 1080p movies roughly under 2GB-3GB.
    - Added `x265/HEVC` Custom Format with a score of `500` to prioritize efficiency without needing background transcoding.
- [2026-02-16] **Workflow Optimization:** Set up "Missing" filter in Radarr to maintain the user's preferred "Queue" view while keeping the library managed.
- [2026-02-18] **Cloudflare & Zero Trust Hardening:**
    - Configured Cloudflare Access for `meals`, `request`, `workout`, and `bridgman` subdomains.
    - Restricted access to specific email list via 6-digit PIN authentication.
    - Implemented a "Bypass" policy for the home public IP to allow seamless internal access.
- [2026-02-18] **Tailscale Networking:**
    - Installed Tailscale Unraid Plugin and enabled "Exit Node" for secure remote browsing.
    - Established private mesh network for family device access to Home Assistant and Unraid GUI.
- [2026-02-18] **App Migration & Integration:**
    - **Mealie:** Migrated from Hyper-V VM to Unraid Docker. Fixed NPM proxy headers and SMTP settings (Port 587/TLS).
    - **Seerr:** Migrated from Overseerr to Seerr (`ghcr.io/seerr-team/seerr`). Integrated into Unraid Community Apps using custom XML template for update tracking.
- [2026-02-18] **Wger Workout Manager Implementation:**
    - Deployed a unified Docker Compose stack (Web, DB, Redis, Nginx helper).
    - Resolved static file rendering issues by using a dedicated Nginx sidecar container.
    - Fixed CSRF verification errors and forced HTTPS `SITE_URL` for mixed-content resolution.
    - Configured Gmail SMTP for email verification.
- [2026-02-18] **DNS Optimization:**
    - Resolved "Split-Brain" DNS loop by removing conflicting local A records in Pi-holes for Cloudflare Tunnel hostnames. This ensures devices use the Cloudflare edge for correct routing and SSL handling.
- [2026-02-20] **Plex Template Repair & Audit:**
    - Fixed corrupted `my-plex.xml`; restored Plex GUI and Docker template management.
    - Added `/transcode` → `/dev/shm` volume mapping so Plex uses RAM for transcoding segments, reducing array and cache I/O.
    - Produced `server_audit.md` with per-category grades (Overall: B). Confirmed ZFS pool is a mirror (`sdc1`/`sdd1`), ARC is capped at 8GB, NPM is v25.09.1 (safe), and disk schedulers are `mq-deadline`.
    - Identified remaining critical gap: no off-server ZFS snapshot replication exists.
- [2026-02-20] **Multi-Agent Context File Created:**
    - Authored `GEMINI.md` to serve as the authoritative architectural state file for all AI agents.
    - Documented the full `icemulnet` static IP map, ZFS pool configuration, and pending task registry.
    - Synchronized findings from `server_audit.md` and `unraid_agent.md` into `GEMINI.md`.

## Next Steps
- **[CRITICAL] Disable Wger open registration:** Set `ALLOW_REGISTRATION=False` in `/mnt/user/appdata/wger/docker-compose.yml` and recreate the `wger` container.
- **[CRITICAL] Implement off-server backup:** Configure ZFS snapshot replication to an external target (USB drive, remote server, or cloud) for `apps/appdata`.
- **[HIGH] Verify Plex Hardware Transcoding:** Confirm "Use hardware acceleration when available" is enabled in Plex Settings → Transcoder.
- **[HIGH] Harden SSH:** Disable password authentication in `/boot/config/go`.
- **[HIGH] Restrict Flash Drive SMB Export** to private in Unraid Main → Flash.
- **[HIGH] Tailscale ACLs:** Restrict family devices to Home Assistant port 8123 only; disable key expiry on the Unraid node.
- **[HIGH] Add TZ variable** to `my-radarr.xml` and `my-sonarr.xml` templates.
- **[HIGH] Install Docker Compose Manager plugin** for Wger GUI visibility.
- **[MEDIUM] Replicate HEVC Custom Format to Sonarr v4.**
- **[MEDIUM] Add security headers** (X-Frame-Options, X-Content-Type-Options) in NPM Advanced tab.
- **[MEDIUM] Add Pi-hole DNS failover** (secondary DNS via DHCP).
- **[MEDIUM] Add container memory limits** (`--memory`) to templates.
- Monitor Cloudflare Security events for blocked unauthorized access attempts.
- Periodically verify ZFS snapshots via the "ZFS Master" plugin.
