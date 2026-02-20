# Session Summary — 2026-02-20

## What Was Accomplished Today

### Plex Template Repair
- The `my-plex.xml` Docker template was corrupted, breaking Plex GUI access and the ability to manage it through the Unraid Docker tab.
- Template was rebuilt/restored. Key fix: added the `/transcode` volume mapping pointing to `/dev/shm` so that all Plex transcoding segments are written to RAM instead of hitting the ZFS cache pool or array, reducing I/O and wear.

### Server Audit (`server_audit.md`)
- A comprehensive server audit document was produced, grading all subsystems with an Overall grade of **B**.
- Categories graded: Security (B-), Storage & Reliability (B), Performance (B-), Docker & Services (B), Networking (B+).
- Key verifications performed:
  - ZFS `apps` pool confirmed as a mirror of `sdc1` and `sdd1`.
  - ZFS ARC confirmed capped at 8GB in `/etc/modprobe.d/zfs.conf`.
  - NginxProxyManager confirmed at v25.09.1 — not vulnerable to the 2.12.x RCE.
  - Disk I/O schedulers confirmed as `mq-deadline` for all array drives.
  - `appdata` share confirmed as `Cache: Only` on the `apps` pool.
- Remaining gaps identified and documented with remediation steps.

### GEMINI.md Creation
- `GEMINI.md` was authored as a persistent multi-agent context file.
- Contains: core SSH/path mandates, full architectural state (ZFS config, ARC settings), the complete `icemulnet` static IP map, and a numbered pending-task registry.
- This file ensures any AI agent can pick up the project state without re-auditing the server.

---

## Key Decisions Made

| Decision | Reasoning |
|----------|-----------|
| Map Plex `/transcode` to `/dev/shm` | Eliminates unnecessary disk writes for transient transcode segments; RAM is fast and ephemeral data does not need persistence. |
| Cap ZFS ARC at 8GB (already set) | Prevents ZFS from consuming all 64GB RAM and starving Docker containers and system processes. |
| Use GEMINI.md as a separate agent-state file | CLAUDE.md is guidance for the Claude agent specifically; GEMINI.md holds the live architectural snapshot suitable for any agent without Claude-specific conventions. |
| No off-server backup yet — flagged CRITICAL | Acknowledged the gap; a mirror protects against drive failure but not against accidental deletion or host-level disaster. |

---

## Open Questions and Next Steps

### Critical
1. **Disable Wger open registration.** `ALLOW_REGISTRATION=True` in `/mnt/user/appdata/wger/docker-compose.yml`. The `workout` subdomain is public-facing via Cloudflare Tunnel. Command to run on host:
   ```bash
   # Edit /mnt/user/appdata/wger/docker-compose.yml — set ALLOW_REGISTRATION=False
   docker compose -f /mnt/user/appdata/wger/docker-compose.yml up -d --force-recreate wger
   ```
2. **Implement off-server ZFS backup.** No snapshot replication exists. Options: USB drive via `zfs send/receive`, Backblaze B2 with `zrepl`, or a second machine on the LAN.

### High Priority
3. Verify Plex Hardware Transcoding is enabled in Plex UI (Settings → Transcoder → "Use hardware acceleration when available").
4. Harden SSH: add `PasswordAuthentication no` to `/boot/config/go` so it survives reboots.
5. Restrict Flash Drive SMB Export to private in Unraid Main → Flash.
6. Tighten Tailscale ACLs: restrict family devices to port 8123 (Home Assistant) only; disable key expiry on Unraid node.
7. Add `TZ` environment variable to `my-radarr.xml` and `my-sonarr.xml`.
8. Install Docker Compose Manager plugin for Wger GUI visibility on the Unraid Docker tab.

### Medium Priority
9. Replicate HEVC/x265 Custom Format from Radarr into Sonarr v4.
10. Add security headers (X-Frame-Options, X-Content-Type-Options) to NPM proxy hosts.
11. Add Pi-hole DNS failover: configure router DHCP with a secondary DNS (1.1.1.1 or router IP).
12. Add `--memory` limits to container templates to prevent OOM events during heavy scans.

---

## Lessons Learned

- **Plex template corruption is silent.** The Unraid Docker tab simply fails to render the container options without a clear error. Always keep a `.bak` of any working XML template before editing on the host.
- **ZFS mirror does not equal backup.** A mirror only protects against a single drive failure. It replicates writes immediately, meaning a destructive `rm -rf` or ransomware event hits both mirror sides. Off-server replication is a separate, mandatory step.
- **GEMINI.md is more useful than expected.** Consolidating the IP map, ZFS settings, and task list into a single agent-readable file reduces ramp-up time significantly when re-entering a session.
- **NPM versioning matters.** The 2.12.x vulnerability was a real concern; confirming v25.09.1 closed that open question quickly and cleanly.

---

## Files Updated This Session

| File | Change |
|------|--------|
| `C:/AI tools/Home/Unraid/unraid_agent.md` | Appended 2026-02-20 log entry; updated Goals Met and Next Steps |
| `C:/AI tools/Home/Unraid/CLAUDE.md` | Added Goals Met, Next Steps, and Logs & Findings sections |
| `C:/AI tools/Home/Unraid/GEMINI.md` | Appended Goals Met, Next Steps, and Session Log sections |
| `C:/AI tools/Home/Unraid/server_audit.md` | Created during session (comprehensive server audit) |
| `C:/AI tools/Home/Unraid/session-summary-2026-02-20.md` | Created (this file) |

---

# Session Summary — 2026-02-20 (Session 2)

## What Was Accomplished Today

### Dual-Agent Server Re-Audit
- Ran a parallel dual-agent audit using the `unraid-homelab-expert` and `gemini-researcher` subagents simultaneously.
- Both agents produced independent findings that were synthesized into a single authoritative document: `server_audit_v2.md`.
- Overall server grade was revised from **A-** to **B+**. The previous grade was considered too generous given three unresolved critical items accumulating across sessions.
- Five new critical or high findings were identified that were not present in `server_audit.md`.

### Credentials Security — Preferences.xml
- `Preferences.xml` was found to be present in the working directory. The file contains a live Plex auth token (`PlexOnlineToken`), account email, and username — all in plaintext.
- `Preferences.xml` was added to `.gitignore` immediately to prevent any future commit from capturing the token.
- Token rotation (sign out and back in on the Plex server) remains outstanding as a CRITICAL next step.

### New Findings from Dual-Agent Audit

| Severity | Finding | Detail |
|----------|---------|--------|
| CRITICAL | Plex token in version-controlled file | `Preferences.xml` held live Plex API token. Gitignored this session; token rotation pending. |
| CRITICAL | ZFS snapshot script logic bugs (4 confirmed) | No exit-code check on `zfs snapshot`; `2>/dev/null` masks all destroy errors; no pool health gate before snapshotting; no persistent logging — failures leave no trace. |
| CRITICAL | Tailscale ACLs (escalated from HIGH) | Exit node active with default allow-all policy. Every Tailnet peer has unrestricted access to all server ports including Unraid GUI, SSH, Radarr, Sonarr, NPM admin, and Prowlarr. |
| HIGH | Plex WanTotalMaxUploadRate = 450000 | Value is in Kbps; 450,000 Kbps = 450 Mbps, effectively uncapped. Intended value is ~4500 for a 4.5 Mbps cap. |
| HIGH | icemulnet subnet is /16 | 65,534 addresses for 7 containers. Risk of silent collision with Docker's default subnet pool (172.16-172.31). Should be /24. |
| HIGH | UMASK=022 in Radarr and Sonarr templates | Makes all written files world-readable (644). Exposes media files and config DBs containing API keys and indexer credentials. Correct value is 002. |
| HIGH | Prowlarr exposed via NPM with no external auth | Prowlarr holds all indexer credentials. It is not behind Cloudflare Zero Trust. The NPM proxy entry should be removed — Prowlarr is accessed internally by container name. |

### Context Files Updated
- `CLAUDE.md`: Goals Met and Next Steps updated to reflect session 2 outcomes.
- `GEMINI.md`: Session Log, Goals Met, Next Steps, and Recent Modifications sections updated.
- `agents.md`: Goals Met, Next Steps, and Session Log updated to match other context files.
- `unraid_agent.md`: New log entry appended; Next Steps updated with all new findings.
- `server_audit_v2.md`: Created as the primary audit reference going forward.

---

## Key Decisions Made

| Decision | Reasoning |
|----------|-----------|
| Grade revised from A- to B+ | Three CRITICAL items have been open for 3+ sessions. The grade must reflect operational reality, not aspirational state. |
| Gitignore Preferences.xml immediately | The token grants full API access to the Plex account. Even with no current remote, the risk of future exposure or accidental push is unacceptable. |
| Escalate Tailscale ACLs to CRITICAL | The combination of exit node enabled plus default allow-all policy means any compromised family device has unrestricted LAN access. This is a lateral movement vector that cannot stay in HIGH. |
| Document ZFS script as CRITICAL rather than MEDIUM | The script is the only local backup mechanism. Silent failures (no logging, no exit-code checks) mean the user has no way to know if snapshots are actually being taken. |
| Use Recyclarr for Sonarr HEVC sync | Recyclarr handles TRaSH Guides Custom Format sync across both arr apps from a single YAML config, avoiding manual JSON export/import and version drift. |

---

## Open Questions and Next Steps

### Critical (act before next session)
1. **Rotate Plex token.** Sign out and back in on the Plex server at `192.168.128.43`. This invalidates the token that was in the repository before `.gitignore` was applied.
2. **Fix `zfs_snapshot.sh`.** Corrected script with exit-code checks, pool health gate, existence check, and persistent logging to `/boot/logs/zfs-snapshot.log` is documented in `server_audit_v2.md` C2.
3. **Implement off-server ZFS backup.** Sanoid+Syncoid to rsync.net or a LAN host. This is 3 sessions overdue. `apps/appdata` contains all container configs, Radarr/Sonarr SQLite DBs, Wger PostgreSQL data, and Plex metadata — a pool-level failure is total service loss with no recovery.
4. **Configure Tailscale ACLs.** Paste the ACL policy from `server_audit_v2.md` C4 into Tailscale Admin. Tag Unraid with `tag:server`, family devices with `tag:family`. Family devices restricted to port 8123 (Home Assistant) only.

### High Priority
5. Fix `WanTotalMaxUploadRate` in Plex: Settings → Remote Access → set to `4500` Kbps (not 450000).
6. Migrate `icemulnet` to `/24`: planned maintenance window required to recreate network and restart all containers. No data loss; all existing static IPs are valid in /24.
7. Change `UMASK` from `022` to `002` in `my-radarr.xml` and `my-sonarr.xml`.
8. Remove or restrict Prowlarr NPM proxy entry — it is an internal-only service; Radarr/Sonarr reach it by container name on icemulnet.
9. Disable Tailscale key expiry on the Unraid node.

---

## Lessons Learned

- **Dual-agent auditing surfaces findings that single-agent audits miss.** The Gemini researcher agent identified the WanTotalMaxUploadRate and icemulnet /16 issues independently from the homelab-expert agent. Synthesis is more thorough than a single pass.
- **`2>/dev/null` in backup scripts is dangerous.** Suppressing all stderr output from `zfs destroy` means the only local backup mechanism can fail silently for an indefinite period. Error output should always go to a log file, not be discarded.
- **Gitignoring a secret after the fact does not rotate the credential.** The `.gitignore` addition prevents future commits from including `Preferences.xml`, but the token that existed in the working directory may have been seen. Token rotation is a separate mandatory step regardless of git history cleanup.
- **A /16 Docker subnet on a common range is a real collision risk.** Docker's default subnet pool overlaps with `172.18.0.0/16`. A `docker network create` without an explicit subnet can silently grab a conflicting range.
- **Exit node + no Tailscale ACLs = full LAN exposure.** The default Tailscale policy is allow-all. Enabling the exit node without ACLs means family devices can reach every port on every LAN host. This is not a theoretical risk — it is the current active state.

---

## Files Updated This Session

| File | Change |
|------|--------|
| `C:/AI tools/Home/Unraid/server_audit_v2.md` | Created — dual-agent re-audit, grade B+, 5 new findings |
| `C:/AI tools/Home/Unraid/.gitignore` | Added `Preferences.xml` entry with explanatory comment |
| `C:/AI tools/Home/Unraid/CLAUDE.md` | Goals Met and Next Steps updated for session 2 outcomes |
| `C:/AI tools/Home/Unraid/GEMINI.md` | Session Log, Goals Met, Next Steps, Recent Modifications updated |
| `C:/AI tools/Home/Unraid/agents.md` | Goals Met, Next Steps, Session Log synced with other context files |
| `C:/AI tools/Home/Unraid/unraid_agent.md` | New log entry appended; Next Steps updated with all new findings |
| `C:/AI tools/Home/Unraid/my-radarr.xml` | TZ=America/New_York confirmed present (already set in prior session) |
| `C:/AI tools/Home/Unraid/my-sonarr.xml` | TZ=America/New_York confirmed present (already set in prior session) |
| `C:/AI tools/Home/Unraid/session-summary-2026-02-20.md` | Session 2 block appended to this file |
