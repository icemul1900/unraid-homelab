# Unraid Server Audit & Improvement Reference — v3
**Generated:** 2026-02-24 | **Server:** 192.168.128.43 | **OS:** Unraid 7.2.3
**Hardware:** Intel i5-10505 (Comet Lake, UHD 630) · 64GB RAM · 15TB array + 1TB ZFS cache (`apps`)
**Sources:** Unraid Homelab Expert Agent + Gemini Research Agent (synthesized)
**Previous grade:** B+ (v2, 2026-02-20)

---

## Overall Grade: A-
**Delta: up from B+**

The remediation pass on 2026-02-23 was thorough and high quality — every HIGH finding from v2 was closed. However, two CRITICALs remain unaddressed for four consecutive sessions, and this audit uncovered six new findings not in v2, including a critical bug in the rewritten ZFS snapshot script that causes it to abort every single run. Fixes for all new findings were applied immediately in this session. The grade is capped at A- by the two persistent CRITICALs (no off-server backup, no Tailscale ACLs) and three newly identified medium items.

| Category | Grade | Delta | Rationale |
|---|---|---|---|
| **Security** | A- | ↑ from B | Token rotated, Prowlarr proxy removed, NPM headers deployed. Tailscale ACLs still open holds it below A. |
| **Storage & Reliability** | B+ | ↑ from B- | ZFS script rewritten; dataset properties set. New CRITICAL: pool health check was broken (fixed this session). No off-server backup remains the ceiling. |
| **Performance** | A- | ↑ from A- | Upload rate fixed, QS active, RAM transcode, lz4 compression. ZFS ARC conservative (LOW). Sonarr HEVC not replicated (MEDIUM). |
| **Docker & Services** | A- | ↑ from B | Healthchecks, memory limits, UMASK correct on arr stack. Plex UMASK (fixed this session), --memory-swap, --health-start-period (fixed this session). |
| **Networking** | B+ | ↑ from B | /24 migration complete, Prowlarr proxy removed, NPM headers global. Tailscale ACLs holding this below A. |
| **Operational Hygiene** | A- | ↑ from B+ | Well-documented audit trail, persistent ZFS logging, version-controlled templates. Minor state inconsistency + no snapshot alerting. |

---

## CRITICAL — Act Before Next Session

### C1 · No Off-Server ZFS Backup (FOUR SESSIONS OVERDUE)

The ZFS mirror (sdc1/sdd1) protects against single drive failure only. The 7 local daily snapshots protect against accidental deletion within the past week. Neither is a backup — there is no copy of `apps/appdata` or `apps/system` on any device outside this physical server.

Total appdata loss scenarios with no recovery path: simultaneous failure of both cache drives, fire/flood/power surge, ransomware reaching the Unraid host, accidental `zpool destroy`, `zfs destroy -r`.

`apps/appdata` contains: Radarr/Sonarr SQLite databases (full library + API keys), Plex metadata (~tens of GB), Wger PostgreSQL data, all container configs.

**Implementation path:**
1. Install **Sanoid** on Unraid — recommended via Nerd Tools (Nerd Pack) plugin: install `perl`, `perl-datetime`, and `perl-config-inifiles`. For persistence across reboots, copy the binary to `/boot/custom/bin/` and add a `go` script entry to restore it on boot.
2. Use **Syncoid** to push incremental ZFS snapshots over SSH to a remote target.
3. Remote targets: **rsync.net** (native ZFS recv support, ~$0.008/GB/month — gold standard for off-site ZFS) or a LAN NAS for fast local recovery.
4. Example replication: `syncoid --compress=zstd apps/appdata user@backup-host:tank/unraid-appdata`
5. Schedule via cron (not User Scripts — User Scripts is for host operations; cron in `/etc/cron.d/` persists better for replication).

**This is the single item that would most improve the server's risk posture.**

---

### C2 · Tailscale ACLs Not Configured (FOUR SESSIONS OVERDUE)

Tailscale's default policy without ACLs is allow-all between all peers. With exit node active, every device on the Tailnet has unrestricted routed access to the entire `192.168.128.0/24` LAN — Unraid GUI, SSH (22), Radarr (7878), Sonarr (8989), NPM admin (81), Prowlarr (9696), etc.

The fix is a 10-minute task in the Tailscale Admin Console. The draft policy below was written in v2 and remains correct:

```jsonc
{
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:family": ["autogroup:admin"]
  },
  "acls": [
    { "action": "accept", "src": ["autogroup:admin"], "dst": ["*:*"] },
    { "action": "accept", "src": ["tag:family"], "dst": ["192.168.128.43:8123"] },
    { "action": "accept", "src": ["tag:family"], "dst": ["autogroup:internet"] }
  ],
  "autoApprovers": { "exitNode": ["tag:server"] }
}
```

**Implementation steps:**
1. Tailscale Admin Console → Access Controls → paste the policy above.
2. Tag the Unraid node: Machines → Tower → Edit tags → add `tag:server`.
3. Tag each family device: Machines → [device] → Edit tags → add `tag:family`.
4. Test: from a family device, verify port 8123 is reachable and port 22/7878/8989 are not.

**Note on syntax:** Use `autogroup:internet` (not `autogroup:internet:*`) for the exit-node route — the port wildcard is not needed and may not be valid in current Tailscale HuJSON.

---

## NEW FINDINGS — Identified in v3 (Fixed This Session)

### N1 · ZFS Snapshot Script: Pool Health Check Was Broken ⚠️ CRITICAL (FIXED)

**File:** `zfs_snapshot.sh`

`zpool status -x apps` (with a pool argument) returns `"pool 'apps' is healthy"` — not `"all pools are healthy"`. The string `"all pools are healthy"` is only returned when `zpool status -x` is called with **no pool argument** (checking all pools at once). The script was using the pool-specific invocation but checking for the all-pools string, causing the health gate to **always evaluate as unhealthy and abort every single run**. The snapshot cron job has not been creating snapshots since the v2 rewrite.

Additionally, `/boot/logs/` is not guaranteed to exist on Unraid's USB-based `/boot`. The `exec >>` redirect fails silently if the directory is missing.

**Both issues were fixed this session:**
```bash
mkdir -p /boot/logs                    # ensure log dir exists
POOL_STATUS=$(zpool status -x)         # no pool arg = "all pools are healthy"
```

**Verify recovery:** SSH into the server and run `zfs list -t snapshot apps/appdata` to confirm no recent snapshots exist. If none, the script has been aborting silently. Run it manually once to create today's snapshot, then verify the log at `/boot/logs/zfs-snapshot.log`.

---

### N2 · Plex UMASK Was Still 022 ⚠️ MEDIUM (FIXED)

Radarr and Sonarr were correctly updated to `UMASK=002` in v2. Plex was missed — `my-plex.xml` line 34 still had `UMASK=022`. Since Plex, Radarr, and Sonarr all share the `/mnt/user/plex/` media tree under the same PUID/PGID, the mismatch creates a permissions inconsistency: Plex-written files (artwork, metadata written outside `/dev/shm`) have group write stripped, which can cause permission collisions when the *arr stack attempts to modify those files.

**Fixed this session:** `my-plex.xml` UMASK → `002`.

---

### N3 · --memory-swap Not Set on Any Container ⚠️ MEDIUM (FIXED)

Docker's behavior when `--memory` is set without `--memory-swap`: swap is automatically set to equal memory, making the effective cap double the stated value. Plex could consume 8g (not 4g), Radarr/Sonarr could consume 2g each (not 1g). The resource limits were softer than documented.

**Fixed this session:** Added `--memory-swap` equal to `--memory` on all three templates, disabling container swap and enforcing the stated caps:
- Plex: `--memory-swap=4g`
- Radarr: `--memory-swap=1g`
- Sonarr: `--memory-swap=1g`

---

### N4 · No --health-start-period on Healthchecks ⚠️ LOW (FIXED)

Radarr and Sonarr require 30–60 seconds of initialization time on startup (database migrations, index loading). Without `--health-start-period`, Docker begins health probing immediately after container start. During normal startup, the health check fails, and the Unraid Docker manager displays the container as `unhealthy`. This is misleading and can cause false-alarm noise.

**Fixed this session:** Added `--health-start-period=30s` to all three container ExtraParams.

---

### N5 · X-XSS-Protection Header Is Deprecated ⚠️ LOW (FIXED)

`X-XSS-Protection: 1; mode=block` was included in `npm_http.conf`. This header is deprecated — modern browsers (Chrome, Firefox, Edge) have removed their XSS auditors entirely. MDN marks it as non-standard. The OWASP recommendation is to use `Content-Security-Policy` instead. The header is a no-op on current browsers and can introduce vulnerabilities in legacy browsers by triggering the old auditor.

**Fixed this session:** Removed from `npm_http.conf`.

---

### N6 · Stale PLEX_CLAIM Token in Template ⚠️ LOW (FIXED)

`my-plex.xml` line 28 contained the literal value `claim-t6qpqEZzrgdv3XDxpuSm` in the `PLEX_CLAIM` variable. Plex claim tokens expire in 4 minutes and are single-use — this token is cryptographically useless and cannot be redeemed. However, it was in the git history of this repo. Not a security vulnerability, but unnecessary noise and a habit to avoid.

**Fixed this session:** `PLEX_CLAIM` value cleared to empty string. The server is already claimed; this variable is only needed on first initialization.

---

## HIGH Priority

### H1 · Disable Tailscale Key Expiry on Unraid Node

Default Tailscale key expiry is 180 days. When the Unraid node's key expires, it silently drops off the Tailnet with no alerting — remote access via Tailscale ceases without warning. Re-authentication requires physical or SSH access. Disabling expiry is safe on a server that never leaves the premises; keep expiry enabled on all family/client devices.

**Fix:** Tailscale Admin Console → Machines → Tower → Disable key expiry.

---

### H2 · binhex-delugevpn: Verify Kill Switch and LAN_NETWORK ⚠️ NEW FINDING

`binhex-delugevpn` (172.18.0.7) has not been audited in any prior session. Two risks to verify:

1. **Kill switch:** The container's built-in iptables kill switch blocks all non-VPN traffic when `VPN_ENABLED=yes`. Verify this is active — if the VPN tunnel drops, downloads should halt, not continue over cleartext. Test: stop the VPN interface inside the container and confirm the Deluge WebUI becomes unreachable from outside icemulnet.

2. **LAN_NETWORK misconfiguration:** If `LAN_NETWORK` is not set to `192.168.128.0/24`, LAN traffic (e.g., Radarr/Sonarr API calls to Deluge) will route through the VPN tunnel and fail. Verify the environment variable is set correctly.

3. **WebUI exposure:** Port 8112 (Deluge WebUI) should not be proxied through NPM without authentication. Restrict to LAN/Tailscale access only.

4. **WireGuard preferred:** If currently using OpenVPN, WireGuard is faster and has a smaller attack surface. Worth switching if the VPN provider supports it.

---

### H3 · Seerr Image Provenance (Third-Party Fork)

`ghcr.io/seerr-team/seerr` is not the official Overseerr (`lscr.io/linuxserver/overseerr`) or Jellyseerr (`fallenbagel/jellyseerr`). It is a community fork that merged both codebases to support Plex and Jellyfin simultaneously. It holds Plex, Radarr, and Sonarr API keys in its database — a compromise is high-impact.

**Risk factors:** Smaller community, slower security patches, no independent security audit.

**Recommendation:** If the server is Plex-only, migrate to official Overseerr (`lscr.io/linuxserver/overseerr`). If Jellyfin compatibility is needed, use official Jellyseerr (`fallenbagel/jellyseerr`). Keep the seerr-team fork only if you have verified its maintenance status and trust the maintainers.

---

## MEDIUM Priority

### M1 · Replicate HEVC Custom Format to Sonarr via Recyclarr

TV downloads remain unoptimized for storage efficiency relative to movies. Radarr has a Custom Format scoring HEVC/x265 at 500 (preferred), Sonarr does not.

**Recyclarr config:**
```yaml
sonarr:
  main:
    base_url: http://192.168.128.43:8989
    api_key: YOUR_SONARR_API_KEY
    custom_formats:
      - trash_ids:
          - "x265 (HD)"
        quality_profiles:
          - name: "Your Quality Profile Name"
            score: 500
```

Run as one-shot: `docker run --rm -v /mnt/user/appdata/recyclarr:/config ghcr.io/recyclarr/recyclarr sync`

Verify the exact TRaSH trash_id at trash-guides.info — IDs can change between releases.

---

### M2 · Add Pi-hole Secondary for DNS Failover

Pi-hole is a single instance. If it goes down, all DNS resolution fails for the LAN. Two options:

- **Option A (simple):** Router DHCP → DNS2 = `1.1.1.1`. Loses local DNS and ad filtering during downtime.
- **Option B (recommended):** Second Pi-hole container on icemulnet at a distinct static IP. **Note:** Gravity Sync (the traditional sync tool) is in maintenance mode and has uncertain compatibility with Pi-hole v6. If running Pi-hole v5, Gravity Sync still works. For Pi-hole v6, use cron-based rsync of `gravity.db`: `rsync -avz /etc/pihole/gravity.db pihole2:/etc/pihole/` and restart the secondary's DNS.

Both instances on the same Unraid host share the same failure domain for hardware events (power loss, drive failure) but provide redundancy for container-level crashes.

---

### M3 · ZFS Dataset: Consider zstd Compression and recordsize

**lz4 vs zstd:** `lz4` is correctly set and is fast/safe. However, for a Docker appdata workload (mixed SQLite databases, config files, Plex metadata), `zstd` (at default level 3) achieves meaningfully better compression ratios with comparable CPU overhead on a modern i5. This is a low-risk improvement: `zfs set compression=zstd apps/appdata apps/system`. Only affects newly written data.

**recordsize for SQLite:** Default recordsize is 128K. SQLite uses 4K pages (default). A 128K recordsize causes significant write amplification on small SQLite transactions — each 4K page write triggers a 128K read-modify-write cycle on ZFS. Setting `recordsize=16K` on `apps/appdata` is a better fit for mixed Docker workloads.

```bash
zfs set compression=zstd apps/appdata apps/system
zfs set recordsize=16K apps/appdata
```

Recordsize only affects new writes. A scrub or rewrite pass would be needed to apply it retroactively — not worth doing for existing data, but beneficial for all new writes from this point forward.

---

### M4 · No Alerting on ZFS Snapshot Failures

The script logs to `/boot/logs/zfs-snapshot.log`, but there is no mechanism to notify the operator if a snapshot fails. A failure can go unnoticed until the next manual log review. Given that C1 (off-server backup) is unimplemented, this is the only local safety net — silent failures are high-risk.

**Options:**
- **Healthchecks.io:** Free tier supports cron job monitoring. Add `curl -fsS https://hc-ping.com/YOUR-UUID > /dev/null` at the end of the script. If the ping is not received within the expected window, an email alert is sent.
- **Unraid notification script:** Use `notify` plugin or write to `/var/log/unraid-api/` to push a notification to the Unraid UI.

---

### M5 · HSTS Note for Cloudflare-Proxied Subdomains

The global `npm_http.conf` includes `Strict-Transport-Security` with a 1-year max-age and `includeSubDomains`. For subdomains that are Cloudflare-proxied (`meals`, `request`, `workout`, `bridgman`), Cloudflare terminates TLS before traffic reaches NPM — the HSTS header set by NPM is **never seen by end clients** on those routes. Configure HSTS for those subdomains at the Cloudflare edge: SSL/TLS → Edge Certificates → HSTS.

For NPM-terminated subdomains (Mealie local, Wger local, etc.), the current HSTS setting is correct. No `preload` directive is correct for homelab — it is irreversible and would require maintaining the domain on browser preload lists.

---

## LOW Priority

### L1 · Verify Plex Remote Access (Tailscale vs Relay)

`Preferences.xml` shows `ManualPortMappingMode="1"` and `LastAutomaticMappedPort="0"`. If no port is actually forwarded at the router, Plex falls back to relay (~2 Mbps cap, latency penalty). Tailscale is the cleaner remote access path: direct peer-to-peer, no port forwarding required, no Cloudflare ToS concern for video streaming. Verify whether family devices accessing Plex remotely are connecting via Tailscale or relay.

### L2 · Verify Wger CSRF_TRUSTED_ORIGINS

The double-proxy setup (NPM → Wger Nginx sidecar → Wger web) required `CSRF_TRUSTED_ORIGINS` to be set correctly at initial deploy. Confirm this is still correct in the Wger compose config after the `icemulnet` migration and any domain changes.

### L3 · Wger ALLOW_REGISTRATION (USER BYPASS)

`ALLOW_REGISTRATION=True` with Cloudflare Zero Trust gating is LOW risk — users must pass email + 6-digit PIN before reaching the registration form. Unauthorized registrations create workout accounts, not admin access. User has opted to keep this for others to register. Consider setting to `False` once all household users are registered.

### L4 · SSH Password Auth (USER BYPASS)

Password auth kept as safety fallback. Note: C2 (Tailscale ACLs) makes this more meaningful — any Tailnet peer can currently reach SSH port 22 directly. Fix C2 first, which limits SSH exposure to admin Tailnet devices only.

### L5 · Consider Increasing ZFS ARC

Current ARC cap: 8GB on 64GB RAM. The `apps` pool holds all Docker appdata. Increasing to 16–24GB allows significantly more metadata and data block caching, reducing latency for Plex metadata databases and frequently accessed container configs. Low-risk change: edit `/etc/modprobe.d/zfs.conf`, set `options zfs zfs_arc_max=<bytes>`, reboot.

### L6 · Consider ZFS ARC Increase for Plex Memory

The Plex memory limit is now `--memory=4g --memory-swap=4g` (hard cap). If Plex runs multiple simultaneous transcodes or performs large metadata scans, 4g may become tight. With 64GB available, raising to 6–8g is safe: `--memory=6g --memory-swap=6g`.

---

## Verification: What Was Fixed Correctly in v2 (Confirmed)

| Item | Verdict |
|------|---------|
| WanTotalMaxUploadRate 450000 → 4500 Kbps | FIXED CORRECTLY |
| Plex memory limit (4g) | FIXED CORRECTLY |
| Plex healthcheck (/identity, 60s, 3 retries) | FIXED CORRECTLY |
| Radarr/Sonarr memory limit (1g each) | FIXED CORRECTLY |
| Radarr/Sonarr healthcheck (/ping, 60s, 3 retries) | FIXED CORRECTLY |
| UMASK 022 → 002 on Radarr and Sonarr | FIXED CORRECTLY |
| ZFS snapshot script structure (duplicate guard, rotation math, error reporting) | FIXED CORRECTLY — pool health check bug found and fixed in v3 |
| ZFS dataset properties (xattr=sa, acltype=posixacl, dnodesize=auto, compression=lz4) | FIXED CORRECTLY |
| icemulnet /16 → /24 migration | FIXED CORRECTLY |
| Prowlarr NPM proxy entry removed | FIXED CORRECTLY |
| NPM global security headers (HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy, Server cleared) | FIXED CORRECTLY — X-XSS-Protection removed in v3 |
| Plex token rotated after git exposure | FIXED CORRECTLY |
| Preferences.xml in .gitignore | FIXED CORRECTLY |

---

## v3 Session Fixes (Applied 2026-02-24)

| File | Change |
|------|--------|
| `zfs_snapshot.sh` | Fixed pool health check (`zpool status -x` no-arg); added `mkdir -p /boot/logs` |
| `my-plex.xml` | UMASK 022 → 002; cleared stale PLEX_CLAIM token; added `--memory-swap=4g`; added `--health-start-period=30s` |
| `my-radarr.xml` | Added `--memory-swap=1g`; added `--health-start-period=30s` |
| `my-sonarr.xml` | Added `--memory-swap=1g`; added `--health-start-period=30s` |
| `npm_http.conf` | Removed deprecated `X-XSS-Protection` header |

---

## Quick-Reference Checklist

```
CRITICAL
[ ] C1 · Off-server ZFS backup via Sanoid+Syncoid (FOUR sessions overdue)
[ ] C2 · Configure Tailscale ACLs (four sessions overdue — 10-minute fix in admin console)

HIGH
[ ] H1 · Disable Tailscale key expiry on Unraid node
[ ] H2 · Verify binhex-delugevpn kill switch, LAN_NETWORK, WebUI exposure  *** NEW ***
[ ] H3 · Audit/replace Seerr image (ghcr.io/seerr-team/seerr)

MEDIUM
[ ] M1 · Replicate HEVC Custom Format to Sonarr via Recyclarr
[ ] M2 · Add Pi-hole secondary + failover (verify Gravity Sync/Pi-hole v6 compat first)
[ ] M3 · ZFS: set compression=zstd and recordsize=16K on apps/appdata   *** NEW ***
[ ] M4 · Add ZFS snapshot failure alerting (healthchecks.io or Unraid notify)  *** NEW ***
[ ] M5 · Configure HSTS at Cloudflare edge for CF-proxied subdomains   *** NEW ***

LOW
[ ] L1 · Verify Plex remote access (Tailscale vs relay)
[ ] L2 · Verify Wger CSRF_TRUSTED_ORIGINS
[ ] L3 · Wger ALLOW_REGISTRATION (USER BYPASS — disable after all users registered)
[ ] L4 · SSH password auth (USER BYPASS — fix C2 first)
[ ] L5 · Consider increasing ZFS ARC to 16-24GB
[ ] L6 · Consider increasing Plex memory cap to 6-8g

FIXED THIS SESSION (v3)
[x] N1 · ZFS snapshot script pool health check (was aborting every run)
[x] N2 · Plex UMASK 022 → 002
[x] N3 · --memory-swap added to all three containers
[x] N4 · --health-start-period=30s added to all three healthchecks
[x] N5 · Deprecated X-XSS-Protection removed from npm_http.conf
[x] N6 · Stale PLEX_CLAIM token cleared from my-plex.xml
```

---

## Hardware Notes: Intel i5-10505 / UHD 630

The i5-10505 is **Comet Lake** (10th gen). iGPU is **Intel UHD Graphics 630**.

| Codec | HW Decode | HW Encode | Notes |
|---|---|---|---|
| H.264 (AVC) | ✓ | ✓ | Full support |
| H.265 (HEVC) 8-bit | ✓ | ✓ | Full support |
| H.265 (HEVC) 10-bit HDR | ✓ | ✓ | Decode/encode yes; **tone mapping is CPU-only** |
| AV1 | ✗ | ✗ | Requires Arc/Alder Lake+ |
| VP9 | ✓ | ✗ | Decode only |

HDR → SDR transcodes fall back to CPU even with QuickSync enabled. UHD 630 does not support OpenCL hardware tone mapping (requires Gen 11 Iris Xe or newer). Intel Arc is the upgrade path if HDR tone mapping becomes a bottleneck.
