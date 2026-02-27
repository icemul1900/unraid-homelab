# Session Summary — 2026-02-23

## What Was Accomplished Today

### Plex & Resource Hardening
- **Fixed Upload Rate:** Corrected `WanTotalMaxUploadRate` (450,000 → 4500 Kbps) in `Preferences.xml`. Verified new token after user restart.
- **Container Limits:** Added memory limits (Plex 4g, Radarr/Sonarr 1g) and healthchecks to all relevant container templates.
- **Permissions:** Tightened `UMASK` to `002` for Radarr and Sonarr to ensure proper file permissions for media and databases.

### Network Migration
- **Migrated `icemulnet` to /24:** Recreated the custom Docker network with the `172.18.0.0/24` subnet and `172.18.0.1` gateway.
- **IP Re-assignment:** Successfully re-attached all 13 containers to the new network with their original static IPs.
- **Verified Connectivity:** Confirmed all containers are up and reachable on the new subnet.

### Security Hardening
- **Removed Prowlarr NPM Proxy:** Removed the public-facing proxy entry for Prowlarr (internal-only service).
- **Global NPM Security Headers:** Added `X-Frame-Options`, `X-Content-Type-Options`, `X-XSS-Protection`, and `Referrer-Policy` globally via NPM custom `http.conf`.

### ZFS & Reliability
- **Repaired Snapshot Script:** Rewrote `zfs_snapshot.sh` to include exit-code checks, pool health gate, existence checks for same-day re-runs, and persistent logging to `/boot/logs/zfs-snapshot.log`.
- **Optimized Dataset Properties:** Set `xattr=sa`, `acltype=posixacl`, `dnodesize=auto`, and `compression=lz4` on `apps/appdata` and `apps/system` for improved database/Docker performance.

---

## Key Decisions Made

| Decision | Reasoning |
|----------|-----------|
| Migrate `icemulnet` to /24 | Eliminates collision risk with Docker's default subnet pool (172.16-31.x.x) and provides better routing precision. |
| Use Global NPM Security Headers | Applying headers via `custom/http.conf` ensures all existing and future proxy hosts are protected by default without manual per-host configuration. |
| Use locally written XML templates | Direct `sed` edits on the host were failing due to complex quoting; writing templates locally and uploading via `scp` is more reliable and version-controlled. |

---

## Open Questions and Next Steps

### Critical
1. **Implement off-server ZFS backup.** Still no replication for the `apps` pool. Sanoid+Syncoid is the recommended path.
2. **Configure Tailscale ACLs.** The LAN is currently exposed to all Tailnet peers. The draft policy in `server_audit_v2.md` C4 must be applied in the Tailscale Admin Console.

### High Priority
3. **Disable Tailscale key expiry** on the Unraid node (Tower) to prevent silent network disconnection.
4. **Remove/Restrict Prowlarr access.** Proxy is removed, but verify internal-only access from Radarr/Sonarr is working via container name.

### Medium Priority
5. **Replicate HEVC Custom Format to Sonarr** using Recyclarr to maintain consistency with Radarr's library optimization.
6. **Add Pi-hole secondary** container with Gravity Sync for DNS failover.

---

## Files Updated This Session

| File | Change |
|------|--------|
| `unraid_agent.md` | Updated Goals Met and Next Steps |
| `GEMINI.md` | Updated architectural state (icemulnet map), Goals Met, and Session Log |
| `agents.md` | Updated Goals Met and Next Steps |
| `zfs_snapshot.sh` | Full rewrite with error handling and logging |
| `my-plex.xml` | Added 4g limit and healthcheck |
| `my-radarr.xml` | Added 1g limit, healthcheck, and UMASK=002 |
| `my-sonarr.xml` | Added 1g limit, healthcheck, and UMASK=002 |
| `npm_http.conf` | Created global security headers file |
| `Preferences.xml` | Updated upload rate (local copy) |
| `session-summary-2026-02-23.md` | Created (this file) |
