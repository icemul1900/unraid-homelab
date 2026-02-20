# Unraid Server Audit & Improvement Reference — v2
**Generated:** 2026-02-20 | **Server:** 192.168.128.43 | **OS:** Unraid 7.2.3
**Hardware:** Intel i5-10505 (Comet Lake, UHD 630) · 64GB RAM · 15TB array + 1TB ZFS cache (`apps`)
**Sources:** Unraid Homelab Expert Agent + Gemini Research Agent (synthesized)

---

## Overall Grade: B+

The previous A- was too generous. Three critical items remain unresolved across multiple sessions, and this audit uncovered new critical findings not previously identified. Grade is capped by: live Plex credentials in a version-controlled file, a confirmed logic bug in the only local backup mechanism, and Tailscale running as an exit node with zero ACLs providing unrestricted lateral LAN access to all Tailnet peers.

| Category | Grade | Delta | Rationale |
|---|---|---|---|
| **Security** | C+ | ↓ from B | Live Plex token in git repo; Tailscale exit node + no ACLs; SSH password auth on; Prowlarr exposed |
| **Storage & Reliability** | B- | ↓ from B | ZFS snapshot script logic bug confirmed; zero off-server backup; ZFS properties incomplete |
| **Performance** | A- | = | Quick Sync active; /dev/shm transcode correct; ARC capped. HDR tone-mapping CPU-only (UHD 630 limit) |
| **Docker & Services** | B | ↓ from B+ | Correct hardlink arch; TZ vars set. No healthchecks, no memory limits, UMASK wrong |
| **Networking** | B | ↓ from B+ | CF ZT + Tailscale + Pi-hole solid. icemulnet /16 misconfigured; no NPM headers; no Pi-hole failover |
| **Operational Hygiene** | C+ | NEW | Credentials in git; open items accumulating 3+ sessions; WanTotalMaxUploadRate 100× wrong |

---

## CRITICAL — Act Before Next Session

### C1 · Plex Credentials Exposed in Version-Controlled File ⚠️ NEW FINDING

`Preferences.xml` is present in this git repository. The file contains in plaintext:

- `PlexOnlineToken="3_WWTQKz_YKCztEfYBQn"` — **live Plex auth token** (full API access to your account)
- `PlexOnlineMail="icemul@gmail.com"` — account email
- `PlexOnlineUsername="ice992"` — account username
- `MachineIdentifier`, `CertificateUUID` — unique device identifiers

The Plex token grants API-level access: enumerate libraries, generate streaming tokens, manage friends, interact with Plex.tv on your behalf. If this repo is ever pushed to a remote or made public, the token is fully compromised.

**Immediate actions:**
1. Add `Preferences.xml` to `.gitignore` immediately.
2. Rotate the Plex token: sign out and back in on the Plex server.
3. Run `git remote -v` — verify this repo has no configured remote the file may have been pushed to.

---

### C2 · ZFS Snapshot Script: Confirmed Logic Bug ⚠️ NEW FINDING

**File:** `zfs_snapshot.sh`

**Bug 1 — No exit-code check on `zfs snapshot`.**
If the script runs twice on the same calendar day (manual re-run, cron overlap, User Scripts retry on reboot), `zfs snapshot` fails with exit code 1. Execution continues unconditionally into the cleanup block, which silently runs against the existing snapshot list. No visibility into whether any individual snapshot succeeded.

**Bug 2 — `2>/dev/null` masks all destroy errors.**
Errors from `zfs destroy` (dataset busy, permission denied, pool degraded) are silently discarded. This is your only local backup mechanism.

**Bug 3 — No pool health gate.**
Snapshots are attempted even on a degraded or faulted pool, which can complicate recovery.

**Bug 4 — No persistent logging.**
Output goes only to User Scripts' ephemeral console. Failures leave no trace on disk.

**Recommended fixes:**
```bash
#!/bin/bash
exec >> /boot/logs/zfs-snapshot.log 2>&1
echo "=== ZFS Snapshot: $(date) ==="

POOL_STATUS=$(zpool status -x apps)
if [ "${POOL_STATUS}" != "all pools are healthy" ]; then
    echo "ERROR: Pool not healthy. Aborting." >&2; exit 1
fi

DATASETS=("apps/appdata" "apps/system")
KEEP=7

for ds in "${DATASETS[@]}"; do
    SNAP_NAME="daily-$(date +%F)"
    if zfs list -t snapshot "${ds}@${SNAP_NAME}" > /dev/null 2>&1; then
        echo "Snapshot ${ds}@${SNAP_NAME} already exists, skipping."
        continue
    fi
    zfs snapshot "${ds}@${SNAP_NAME}" || { echo "ERROR: Failed to create ${ds}@${SNAP_NAME}" >&2; continue; }
    echo "Created ${ds}@${SNAP_NAME}"
    zfs list -H -t snapshot -o name -S creation -r "${ds}" | grep "@daily-" | tail -n +$((KEEP + 1)) | while read snap; do
        zfs destroy "${snap}" && echo "Destroyed ${snap}" || echo "WARNING: Failed to destroy ${snap}" >&2
    done
done
echo "=== Completed: $(date) ==="
```

**Long-term:** Replace with **Sanoid** (local policy management) + **Syncoid** (ZFS send/receive replication). This is the community-standard tool for exactly this use case.

---

### C3 · No Off-Server Backup (Escalated — 3 Sessions Overdue)

ZFS snapshots are on the same physical hardware as the data. The mirror protects against single drive failure only — not against accidental `rm -rf`/`zfs destroy`, pool-level corruption, physical loss, or ransomware. `apps/appdata` contains all container configs, Radarr/Sonarr SQLite DBs, Wger PostgreSQL data, and Plex metadata. A pool-level failure is total service loss with zero recovery path.

**Recommended implementation path:**
1. Install **Sanoid** via Nerd Tools plugin or Docker container on icemulnet
2. Use **Syncoid** to push incremental snapshots via SSH to a remote target
3. Remote target options: **rsync.net** (~$0.008/GB/month, native ZFS recv support) or a LAN backup machine
4. Example push: `syncoid --compress=zstd apps/appdata user@backup-host:tank/unraid-appdata`

---

### C4 · Tailscale Exit Node with No ACLs (Escalated from HIGH)

Default Tailscale policy is allow-all. Every Tailnet peer has full bidirectional access to every device on all ports. With exit node active:

- Any family device can reach `192.168.128.43` on ALL ports: Unraid GUI, SSH (22), Radarr (7878), Sonarr (8989), NPM admin (81), Prowlarr (9696), etc.
- A compromised family device is a direct lateral movement vector into your entire LAN.
- The intended policy (family → HA port 8123 only) is **not currently enforced**.

**Recommended ACL policy (paste into Tailscale Admin → Access Controls):**
```jsonc
{
  "tagOwners": {
    "tag:server": ["autogroup:admin"],
    "tag:family": ["autogroup:admin"]
  },
  "acls": [
    { "action": "accept", "src": ["autogroup:admin"], "dst": ["*:*"] },
    { "action": "accept", "src": ["tag:family"], "dst": ["192.168.128.43:8123"] },
    { "action": "accept", "src": ["tag:family"], "dst": ["autogroup:internet:*"] }
  ],
  "autoApprovers": { "exitNode": ["tag:server"] }
}
```
Tag Unraid with `tag:server`; family devices with `tag:family`. The `autogroup:internet` line preserves exit-node internet routing while blocking all LAN access except HA port 8123.

---

## HIGH Priority

### H1 · Plex WanTotalMaxUploadRate is 100× Wrong ⚠️ NEW FINDING

`Preferences.xml`: `WanTotalMaxUploadRate="450000"`. Plex stores this in **Kbps**. `450,000 Kbps = 450 Mbps` — effectively uncapped. The intended value for ~4.5 Mbps cap is `4500`.

**Fix:** Plex Settings → Remote Access → Upload speed → set to `4500` (or your actual intended cap in Kbps).

---

### H2 · icemulnet Subnet is /16 — Should Be /24 ⚠️ NEW FINDING

`172.18.0.0/16` allocates 65,534 addresses for 7 containers. Problems:
1. **Routing collision risk:** Docker's default subnet pool uses `172.16–172.31`. A new `docker network create` without an explicit subnet may collide with icemulnet silently.
2. **ACL precision:** Tight inter-container firewall rules are impractical on a /16.

**Fix:** Recreate the network as `172.18.0.0/24`. All existing static IPs (`.3`–`.13`) are valid in a /24. Requires a planned maintenance window to recreate the network and restart all containers — no data loss.

---

### H3 · UMASK=022 Should Be 002 ⚠️ NEW FINDING

Both Radarr and Sonarr set `UMASK=022`, making all written files world-readable (644/755). Any process or container on the host can read media files and config databases (which contain API keys, indexer credentials, download client passwords).

`UMASK=002` is correct: 664 files, 775 dirs, owned by `nobody:users`. Preserves hardlink/atomic-move behavior. Change in both XML templates.

---

### H4 · Prowlarr Has No Authentication Layer at Network Edge ⚠️ NEW FINDING

Prowlarr (`.3` on icemulnet, port 9696) holds all indexer credentials and API keys. It is not in the Cloudflare Zero Trust protected domains list. Per C4, any Tailnet peer can reach it directly. Options:
- Add a Cloudflare Access policy in front of its NPM proxy entry, OR
- **Remove the NPM proxy entry entirely** — Prowlarr is an internal-only service; Radarr/Sonarr access it by container name on icemulnet. No external proxy needed.

---

### H5 · Disable Tailscale Key Expiry on Unraid Node

Default key expiry is 180 days. If the Unraid node expires, it drops off the Tailnet silently with no alerting. Re-auth requires physical or SSH access. Safe to disable on a server that never leaves home — keep expiry **enabled** on all family/client devices.

**Fix:** Tailscale Admin Console → Machines → Unraid node → Disable key expiry.

---

### H6 · [ON HOLD] SSH Hardening
**[STATUS: USER BYPASS]** Keeping password auth enabled as safety fallback. Note: per the research, this is a brute-force risk if a Tailnet device is compromised (C4 makes this more urgent — fix C4 first).

---

## MEDIUM Priority

### M1 · Optimize ZFS Dataset Properties

Current: `atime=off` ✓ `autotrim=on` ✓ | `xattr=sa` ✗ `acltype=posixacl` ✗ `dnodesize=auto` ✗ `compression=lz4` ✗

**Run as root on Unraid:**
```bash
zfs set xattr=sa acltype=posixacl dnodesize=auto compression=lz4 apps/appdata
zfs set xattr=sa acltype=posixacl dnodesize=auto compression=lz4 apps/system
```

- `xattr=sa` — stores xattrs in inodes vs hidden dirs; critical for Docker/database workloads
- `dnodesize=auto` — **required** alongside `xattr=sa` to prevent inode overflow
- `compression=lz4` — CPU-cheap, reduces I/O for config files and databases
- Properties apply to new data only; no pool export/import required; zero downtime

**Optional — Wger PostgreSQL:**
```bash
zfs set recordsize=8K apps/appdata/wger-db   # if it's a separate dataset
```
Matches PostgreSQL's 8K page size, reduces write amplification significantly.

---

### M2 · Fix ZFS Snapshot Script

See C2 for the corrected script. Minimum changes: add existence check, pool health gate, exit-code checking, and persistent logging. Replace with Sanoid/Syncoid long-term (also addresses C3).

---

### M3 · Add Container Healthchecks ⚠️ NEW FINDING

Neither Radarr nor Sonarr define a Docker healthcheck. Both are known to enter hung states after large library scans — Docker has no detection mechanism for this. Add to each template's `ExtraParams`:

**Radarr:**
```
--health-cmd="curl -sf http://localhost:7878/ping || exit 1" --health-interval=60s --health-retries=3
```
**Sonarr:**
```
--health-cmd="curl -sf http://localhost:8989/ping || exit 1" --health-interval=60s --health-retries=3
```

---

### M4 · Add Container Memory Limits

| Container | ExtraParams to add |
|---|---|
| Radarr | `--memory=1g --memory-swap=1g` |
| Sonarr | `--memory=1g --memory-swap=1g` |
| Plex | `--memory=4g --memory-swap=4g` |
| Mealie | `--memory=512m --memory-swap=512m` |
| Pi-hole | `--memory=256m --memory-swap=256m` |
| NPM | `--memory=256m --memory-swap=256m` |

Setting `--memory-swap` equal to `--memory` disables swap for the container (OOM-kill instead of thrash).

---

### M5 · Replicate HEVC Custom Format to Sonarr v4

**Recommended tool: Recyclarr** (`ghcr.io/recyclarr/recyclarr`) — Docker container that syncs TRaSH Guides Custom Formats and quality profiles to both Radarr and Sonarr from a single YAML config. Handles differing `trash_id` values between apps automatically.

**Manual alternative:** Radarr → Settings → Custom Formats → export as JSON → paste into Sonarr v4 Custom Formats → import.

---

### M6 · Add Security Headers to NPM

Add to the Advanced tab of each proxy host:
```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;
more_clear_headers Server;
more_clear_headers X-Powered-By;
```

**Notes:**
- Do NOT use `preload` on HSTS for homelab domains — it is irreversible and breaks internal-only domains.
- Do NOT double-add HSTS on Cloudflare-proxied hosts (meals, request, workout, bridgman) — Cloudflare handles it at the edge.
- Priority targets: Mealie and Wger (user-facing login forms).

---

### M7 · Add Pi-hole DNS Failover

**Option A (simple):** Configure router DHCP → DNS2 = `1.1.1.1`. Loses local DNS resolution and ad filtering during Pi-hole downtime.

**Option B (recommended for your architecture):** Run a second Pi-hole container on icemulnet at a different static IP. Use **Gravity Sync** to keep databases in sync. Both IPs in router DHCP. Local A records and filtering survive single-instance failure.

---

## LOW Priority

### L1 · Plex Remote Access — Relay Risk

`Preferences.xml`: `ManualPortMappingMode="1"` + `LastAutomaticMappedPort="0"`. If no port is actually forwarded, Plex uses relay (~2 Mbps cap). **Recommended:** Use Tailscale for remote Plex access — direct peer-to-peer, no port forwarding, no relay. Cleaner than port forwarding and avoids Cloudflare ToS issues for video streaming.

### L2 · Verify Wger CSRF_TRUSTED_ORIGINS

Double-proxy (NPM → Wger Nginx → Wger web) caused CSRF issues at initial deploy. Confirm `CSRF_TRUSTED_ORIGINS` is still correctly set in the Wger compose config to prevent regression.

### L3 · Audit Seerr Image Provenance

`ghcr.io/seerr-team/seerr` is a third-party fork, not the original Overseerr/Jellyseerr. It holds Plex, Radarr, and Sonarr API keys. Verify it is actively maintained and you trust its provenance.

### L4 · Consider Increasing ZFS ARC

Current cap: 8GB. On 64GB RAM, increasing to 16–24GB allows more aggressive metadata caching without impacting Docker/VM workloads. Low priority — current setup is functional.

---

## Hardware Notes: Intel i5-10505 / UHD 630

The i5-10505 is **Comet Lake** (10th gen, 14nm), not Tiger Lake. iGPU is **Intel UHD Graphics 630**.

| Codec | HW Decode | HW Encode | Notes |
|---|---|---|---|
| H.264 (AVC) | ✓ | ✓ | Full support, very fast |
| H.265 (HEVC) 8-bit | ✓ | ✓ | Full support |
| H.265 (HEVC) 10-bit HDR | ✓ | ✓ | Decode/encode yes; **tone mapping is CPU-only** |
| AV1 | ✗ | ✗ | Requires Arc/Alder Lake or newer |
| VP9 | ✓ | ✗ | Decode only |

**HDR limitation:** UHD 630 does not support OpenCL hardware tone mapping (requires Gen 11 Iris Xe or newer). HDR → SDR transcodes fall back to CPU even with Quick Sync enabled. If HDR tone mapping performance becomes a bottleneck, an Intel Arc GPU is the upgrade path.

---

## Quick-Reference Checklist

```
CRITICAL
[ ] C1 · Add Preferences.xml to .gitignore + rotate Plex token          *** NEW ***
[ ] C2 · Fix ZFS snapshot script (exit codes, health gate, logging)      *** NEW ***
[ ] C3 · Implement off-server ZFS backup via Sanoid+Syncoid (3 sessions overdue)
[ ] C4 · Configure Tailscale ACLs (escalated from HIGH)

HIGH
[ ] H1 · Fix Plex WanTotalMaxUploadRate (450000 → 4500 Kbps)            *** NEW ***
[ ] H2 · Migrate icemulnet to /24                                        *** NEW ***
[ ] H3 · Change UMASK from 022 → 002 in Radarr + Sonarr templates       *** NEW ***
[ ] H4 · Remove/restrict Prowlarr NPM proxy entry                        *** NEW ***
[ ] H5 · Disable Tailscale key expiry on Unraid node
[~] H6 · SSH hardening (ON HOLD — user preference)

MEDIUM
[ ] M1 · Set xattr=sa, acltype=posixacl, dnodesize=auto, compression=lz4
[ ] M2 · Fix zfs_snapshot.sh (see corrected script above)
[ ] M3 · Add healthchecks to Radarr + Sonarr ExtraParams                *** NEW ***
[ ] M4 · Add --memory limits to all containers
[ ] M5 · Replicate HEVC Custom Format to Sonarr (use Recyclarr)
[ ] M6 · Add security headers to NPM proxy hosts
[ ] M7 · Add Pi-hole secondary / failover instance

LOW
[ ] L1 · Verify Plex remote access (Tailscale > port forwarding)
[ ] L2 · Verify Wger CSRF_TRUSTED_ORIGINS
[ ] L3 · Audit Seerr image provenance
[ ] L4 · Consider increasing ZFS ARC to 16-24GB
```
