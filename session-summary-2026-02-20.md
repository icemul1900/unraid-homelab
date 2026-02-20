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
