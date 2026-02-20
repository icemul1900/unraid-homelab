# Unraid Server Audit & Improvement Reference
**Generated:** 2026-02-20 | **Server:** 192.168.128.43 | **OS:** Unraid 7.2.3
**Hardware:** Intel i5-10505 (6C/12T) · 64GB RAM · 15TB array + 1TB ZFS cache (`apps`)

---

## Overall Grade: B

| Category | Grade | Rationale |
|---|---|---|
| **Security** | B− | CF + Tailscale active; NPM v25+ is safe; SSH key found, but Wger registration still open. |
| **Storage & Reliability** | B | **[VERIFIED]** Apps pool is a ZFS Mirror; Snapshots active; `atime=off` set. No off-server backup. |
| **Performance** | B− | iGPU `/dev/dri` found; ZFS ARC capped at 8GB; HDD schedulers set to `mq-deadline`. |
| **Docker & Services** | B | Correct hardlink architecture; `appdata` on Cache Only. Missing TZ vars. |
| **Networking** | B+ | Solid Cloudflare Zero Trust + Tailscale + Pi-hole split-brain fix. |

---

## CRITICAL — Act Immediately

### C1 · Disable Wger Open Registration
`ALLOW_REGISTRATION` is currently `True` in `/mnt/user/appdata/wger/docker-compose.yml`. The `workout` subdomain is publicly routed via Cloudflare Zero Trust.
```bash
# Edit /mnt/user/appdata/wger/docker-compose.yml:
ALLOW_REGISTRATION=False
# Then restart:
docker compose -f /mnt/user/appdata/wger/docker-compose.yml up -d --force-recreate wger
```

### C2 · [PASSED] Verify NPM Version
**[STATUS: OK]** Your NginxProxyManager is running version **25.09.1**, which is well beyond the vulnerable 2.12.x range. No action required.

### C3 · Implement Off-Server Backup for ZFS Appdata (CRITICAL GAP)
While your pool is now a mirror (redundant), a local disaster or accidental `rm -rf` still poses a risk. You currently have **zero** off-server backup.

---

## HIGH Priority

### H1 · [COMPLETED] Add ZFS Pool Mirror
**[STATUS: OK]** Verified `apps` pool is a mirror of `sdc1` and `sdd1`. Redundancy is established.

### H2 · Enable Plex Hardware Transcoding (Intel QuickSync / UHD 630)
**[STATUS: PARTIAL]** `/dev/dri/renderD128` exists on host and is mapped in the Plex template.
**Next Step:** Verify "Use hardware acceleration when available" is checked in Plex Settings → Transcoder.

### H3 · Harden SSH Access
**[STATUS: PARTIAL]** `authorized_keys` found for root. However, password auth is not yet disabled in `/boot/config/go`.

### H4 · Restrict Flash Drive SMB Export
Navigate to: `Main → Flash → SMB Export` → Set to **"No"** or **"Yes (Hidden) - Private"**.

### H5 · Tighten Tailscale ACLs
Restrict family devices to Home Assistant port 8123 only via the Tailscale Admin Console.

### H6 · Disable Tailscale Key Expiry on the Unraid Node
Prevent accidental lockout by disabling key expiry in the Tailscale Machine settings.

### H7 · [COMPLETED] Verify Appdata Share is "Cache: Only"
**[STATUS: OK]** Verified `shareUseCache="only"` and `shareCachePool="apps"` in `appdata.cfg`.

### H8 · Add TZ Environment Variable to Radarr and Sonarr
Templates are missing the `TZ` variable. Add to `my-radarr.xml` and `my-sonarr.xml` via the Docker tab (Advanced View).

### H9 · Install Docker Compose Manager Plugin for Wger
The Wger stack is currently managed manually via CLI. Install the plugin for GUI visibility.

---

## MEDIUM Priority

### M1 · [PARTIAL] Optimize ZFS Dataset Properties
- `atime=off`: **[SET]** (Inherited from pool)
- `autotrim=on`: **[SET]**
- `xattr=sa`: **[NOT SET]** (Currently `on`)
- `acltype=posixacl`: **[NOT SET]** (Currently `posix`)
- `recordsize`: **[NOT SET]** (Currently `128k` for all)

### M2 · Add ZFS Snapshot Error Handling
Update `zfs_snapshot.sh` to handle duplicate snapshots and log errors instead of suppressing them.

### M3 · [COMPLETED] Cap ZFS ARC
**[STATUS: OK]** `zfs_arc_max` is set to **8GB** in `/etc/modprobe.d/zfs.conf`.

### M4 · Map Plex Transcode to RAM (/dev/shm)
**[STATUS: OK]** Repaired Plex template now includes `/transcode` → `/dev/shm`.

### M5 · Replicate HEVC Custom Format in Sonarr v4
Configure Sonarr v4 Custom Formats to match Radarr's HEVC preference.

### M6 · Add Security Headers to NPM Proxy Hosts
Add `X-Frame-Options`, `X-Content-Type-Options`, etc., to the Advanced tab of your NPM proxy hosts.

### M7 · Add Pi-hole DNS Failover
Configure router DHCP to provide a secondary DNS server (Router or 1.1.1.1) in case Pi-hole is down.

### M8 · Add Container Resource Limits
Add `--memory` limits to templates to prevent OOM killer issues during heavy scans.

---

## LOW Priority / Long-Term

### L1 · [COMPLETED] Disk I/O Scheduler Tuning
**[STATUS: OK]** All array HDDs (`sda`, `sdb`, `sdc`, `sdd`) are already using `mq-deadline`.

### L9 · [PARTIAL] Document the icemulnet IP Map
**Current icemulnet (172.18.0.0/16):**
- `172.18.0.3`: prowlarr
- `172.18.0.4`: seerr
- `172.18.0.5`: NginxProxyManager
- `172.18.0.6`: sonarr
- `172.18.0.9`: radarr
- `172.18.0.10`: Mealie
- `172.18.0.13`: wger-web

---

## Quick-Reference Checklist

```
CRITICAL
[ ] C1 · Set ALLOW_REGISTRATION=False in wger/docker-compose.yml
[x] C2 · [PASSED] NPM is v25.09.1
[ ] C3 · Implement off-server ZFS appdata backup

HIGH
[x] H1 · [COMPLETED] Apps pool is a mirror
[ ] H2 · Verify Plex HW Transcoding is enabled in Plex UI
[ ] H3 · Disable SSH password auth in /boot/config/go
[ ] H4 · Set Flash SMB Export to private
[ ] H5 · Add Tailscale ACLs
[ ] H6 · Disable Tailscale key expiry
[x] H7 · [COMPLETED] Appdata share = Cache: Only
[ ] H8 · Add TZ variable to Radarr/Sonarr
[ ] H9 · Install Docker Compose Manager plugin

MEDIUM
[ ] M1 · Tune ZFS xattr, acltype, and recordsize
[ ] M2 · Fix ZFS snapshot script error handling
[x] M3 · [COMPLETED] ZFS ARC is capped at 8GB
[x] M4 · [COMPLETED] Plex /transcode mapped to /dev/shm
[ ] M5 · Add HEVC Custom Formats to Sonarr v4
[ ] M6 · Add security headers to NPM
[ ] M7 · Add Pi-hole DNS fallback
[ ] M8 · Add --memory limits to containers
```
