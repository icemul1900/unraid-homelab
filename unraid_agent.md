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

## Next Steps
- Monitor Cloudflare Security events for blocked unauthorized access attempts.
- Re-evaluate Wger `ALLOW_REGISTRATION` setting (change to `False` once friends have joined).
- **Remote Desktop Replacement:** Plan implementation of RustDesk on Unraid to replace TeamViewer.
- Periodically check ZFS snapshots via "ZFS Master" plugin.
