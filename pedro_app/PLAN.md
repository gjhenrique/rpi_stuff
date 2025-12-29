### Homelab modernization plan (single source of truth)

This is the **only planning document** you need to implement later (with an agentic IDE/coding platform).

It describes a full modernization of your `pedro_app/` homelab around:
- **Komodo** deployments (GitOps-ish), using **polling** (no inbound webhooks)
- **Your own private Tailscale tailnet** (no shared account)
- **Per-stack Tailscale sidecar** model (tagged devices per service)
- **Mullvad exit nodes** applied **only** to the torrent stack
- **Samba accessible on both LAN and Tailscale**
- **Backups with restic via autorestic**: local full + B2 offsite for service state (DB/metrics/config)
- **Immich** adoption for photos (migration-ready)
- **Hardware migration**: Pi now → N100 NAS later with **manual RAID**

References:
- Komodo webhooks (background only; we’ll use polling): [Komodo – Configuring Webhooks](https://komo.do/docs/resources/webhooks)
- Mullvad in Tailscale: [Tailscale – Mullvad exit nodes](https://tailscale.com/kb/1258/mullvad-exit-nodes)

---

### 0) Non-negotiable principles

- **Day‑2 operations are Komodo-only**: once bootstrapped, you don’t run `ansible-playbook` for app changes.
- **Bootstrap is Ansible-only**: Ansible is allowed, but only to bring a host to a known base state (packages, mounts, users, firewall).
- **Default-private**: every service is reachable only via **Tailscale** (except Samba, which is also reachable on LAN).
- **Stable storage paths**: Compose stacks never reference `/dev/sdX`; they reference `/srv/...`.
- **Restorable**: backups include **Prometheus blocks** and **Postgres volumes** so you can fully restore services.

---

### 1) Procurement / accounts (do this first)

#### 1.1 Create a private Tailscale tailnet
- Create your own Tailscale account and tailnet.
- Do **not** invite your friend (clear separation).

#### 1.2 Decide on Tailscale plan + enable Mullvad add-on
- Choose a Tailscale plan that fits your device count.
- Enable/purchase the **Mullvad add-on** and confirm Mullvad exit nodes are available.
  Reference: [Tailscale – Mullvad exit nodes](https://tailscale.com/kb/1258/mullvad-exit-nodes)

#### 1.3 Decide on naming/tagging conventions (important for long-term sanity)
Recommended:
- Hostnames:
  - `pedro-komodo` (Komodo Core)
  - `pedro-share`, `pedro-torrent`, `pedro-observability`, `pedro-immich`, …
- Tags:
  - `tag:pedro-mgmt` (admin/owner tag)
  - `tag:pedro-share`, `tag:pedro-torrent`, `tag:pedro-observability`, `tag:pedro-immich`, …

---

### 2) Komodo deployment model (polling; no inbound webhooks)

You chose **polling** so Komodo stays tailnet-only and you don’t expose `/listener/*` publicly.

Background reference (not used with polling): Komodo webhooks are under `/listener/...` and require a public proxy if Komodo is private.
Source: [Komodo – Configuring Webhooks](https://komo.do/docs/resources/webhooks)

#### 2.1 Komodo “Core vs Periphery” (plain terms)
- **Komodo Core**: the UI/API + DB (the thing you log into).
- **Komodo Periphery**: the agent that runs on each server and actually runs compose actions.

Your decision:
- **Core runs on the Raspberry Pi for now**, migrate to N100 later.
- Periphery runs on **each** target host (Pi now, N100 later).

#### 2.2 “Deploy on push to main” with polling
Implementation concept:
- Komodo tracks your Git repo.
- It periodically polls/pulls `main`.
- When it sees changes, it redeploys affected stacks.

Policy recommendation:
- Use a short interval (e.g. 1–2 minutes).
- Prefer “deploy only on `main`”.
- Use PRs + review to keep `main` stable.

Rollback recommendation:
- Tag releases in Git or use Git revert.
- Komodo redeploys from the reverted `main`.

---

### 3) Network model (Tailscale sidecar per stack)

You chose: **each stack has a Tailscale sidecar node**.

Rules:
- Each service stack gets its own Tailscale identity (hostname + tag).
- App containers run with `network_mode: service:tailscale` so:
  - The service is **not** exposed on host LAN ports by default
  - The only ingress is through the tailnet node

#### 3.1 ACL policy shape (high-level)
In your new tailnet:
- Only your user(s) can reach `tag:pedro-*` devices.
- Explicitly allow ports per service.
- Enable Tailscale SSH for admin, but restrict by group.

Samba requires explicit SMB allowances (see §4).

---

### 4) Samba (LAN + Tailscale)

Your requirements:
- LAN CIDR: **`192.168.0.0/24`**
- Samba should be reachable:
  - from LAN devices
  - from tailnet devices via `pedro-share:<samba_port>` (example: `pedro-share:445`)

Recommended architecture (fits sidecar-per-stack):
- Samba runs in the **share stack** using `network_mode: service:tailscale` (so it is reachable over Tailscale).
- To also serve LAN clients, you publish ports on the **tailscale sidecar service** (because the network namespace is the sidecar’s):
  - TCP **445** (SMB)
  - optionally TCP **139** for legacy clients

Security policy:
- **LAN firewall**: allow from `192.168.0.0/24` → TCP 445 (and 139 if used).
- **Tailscale ACL**: allow only your user/group → `tag:pedro-share:445` (and optionally 139).

Operational note:
- SMB discovery via broadcast is optional. Plan for “connect by hostname/IP”.

---

### 5) Mullvad scope (torrent stack only)

Your requirement: Mullvad should affect **only** the torrent workload.

Implementation concept:
- Only the **torrent stack’s** Tailscale sidecar uses `--exit-node=<mullvad-node>` (and `--exit-node-allow-lan-access=true` if needed).
- No other stack uses an exit node.

Reference: [Tailscale – Mullvad exit nodes](https://tailscale.com/kb/1258/mullvad-exit-nodes)

---

### 6) Storage plan (Pi now → N100 NAS later; manual RAID)

#### 6.1 Stable mountpoints (mandatory)
All stacks use:
- `/srv/appdata/<stack>/...` for state/config/db
- `/srv/storage/...` for bulk data

Recommended structure:
- `/srv/appdata/`
  - `observability/` (Prometheus TSDB, Grafana data)
  - `immich/` (db, redis, ML cache)
  - `paperless/` …
- `/srv/storage/`
  - `media/` (downloads, movies, etc)
  - `pictures/immich/` (Immich originals)
  - `documents/`

#### 6.2 Pi (today)
- Keep your external SSD/HDD/NVMe, but present them via the stable `/srv/...` paths (mount + bind mount as needed).

#### 6.3 N100 NAS (future)
You want a simple Linux distro (Manjaro/Arch) and **manual RAID**.

Plan:
- Create RAID (mdadm).
- Create filesystem (ext4 or xfs).
- Mount RAID at `/srv/storage`.
- Choose `/srv/appdata` location:
  - best: NVMe/SSD (fast DB/TSDB)
  - acceptable: on RAID

Migration strategy:
- Make the N100 mount paths match `/srv/...`.
- Rsync `/srv/appdata` and selected parts of `/srv/storage`.
- Point Komodo deployments at the new server and redeploy.

---

### 7) Backups (autorestic + restic): full restore + cost control

Your requirements:
- Full recovery for services (include **Prometheus blocks** + **Postgres volumes**).
- Offsite B2 only for “configs and other stuff” (no torrents/media; photos not offsite unless you later opt in).

Recommended policy:

#### 7.1 Local backups (full restore)
- Backup:
  - `/srv/appdata` (DBs, Prometheus TSDB, configs, etc.)
  - `/srv/storage` (bulk data: media, documents, Immich originals)
- Destination: local restic repo on a dedicated backup disk/path.

#### 7.2 B2 offsite backups (service restore; excludes bulk)
- Backup:
  - `/srv/appdata` only (so you can restore all services and their data/DB/metrics)
- Exclude by policy:
  - `/srv/storage` (torrents/media)
  - `/srv/storage/pictures/immich` (Immich originals) unless you decide you want photo disaster recovery

Reality check:
- With this policy, a total-loss event means you can restore the *services and databases*, but not photo originals (unless those exist elsewhere).

---

### 8) Immich migration plan (prepare now)

Goal: migrate photos from the current solution to Immich.

Plan:
- Deploy Immich as its own stack (`pedro-immich` sidecar tag).
- Storage:
  - originals: `/srv/storage/pictures/immich`
  - appdata: `/srv/appdata/immich`
- Migration:
  - import existing photo library into Immich originals path
  - let Immich index/scan

Backups:
- Local: includes originals + appdata
- B2: includes appdata only

---

### 9) Execution roadmap (phased)

#### Phase A — foundation (Pi)
- Create new tailnet + enroll your devices
- Enable Mullvad add-on
- Bootstrap Pi via Ansible:
  - docker/compose
  - tailscale host setup
  - directories `/srv/appdata` + `/srv/storage`
  - firewall base policy
  - autorestic/restic install + timers
  - Komodo Core + Periphery

#### Phase B — move one service end-to-end (template)
- Pick one service (paperless or observability) and deploy via Komodo with its own sidecar.
- Validate: Tailscale access only, persistence, backups.

#### Phase C — migrate torrent + Mullvad-only egress
- Deploy torrent stack with `pedro-torrent` sidecar
- Configure sidecar to use Mullvad exit node
- Validate egress IP from inside torrent containers

#### Phase D — migrate share stack + Samba LAN+Tailscale
- Deploy share stack with `pedro-share` sidecar
- Publish SMB ports for LAN and allow via firewall/ACL

#### Phase E — add Immich + start photo migration
- Deploy Immich stack
- Migrate/ingest photos

#### Phase F — hardware migration to N100 NAS
- Build NAS, set up RAID manually
- Mount at `/srv/storage` (same as Pi plan)
- Install periphery, redeploy stacks, migrate data

