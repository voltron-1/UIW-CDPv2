# Phase 1 Evidence — Stand up the SO grid

**Milestone:** M2 / [#10](https://github.com/voltron-1/UIW-CDPv2/issues/10) ·
**Gate:** Gate 1 · **Started:** 2026-07-05 · **Status:** ⏳ In progress —
ISO verified (A1), SO Standalone installed (A2), **`so-status` green (A3, host
`cardinal-so`)**. Remaining for Gate 1: confirm SOC-console login, and get
sensor events (monitor NIC has no live traffic yet).

> Golden rule 4: every gate produces evidence here — command output, screenshots
> by filename, issue links. This file is the capstone-demo record for Phase 1.
> Fill each section's **Result** as the step is executed; nothing is fabricated
> ahead of time.

**Gate 1 exit criteria** (milestone #10, verbatim): `so-status` clean · SOC
console up · SO's own sensors producing events into Elasticsearch · old ELK
still running untouched in parallel.

**Blocker:** Steps A1–A4 are on-hardware `[HUMAN]` work that cannot begin until
the remaining [#160 / P0.4](https://github.com/voltron-1/UIW-CDPv2/issues/160)
hardware values (Target Host, NIC Layout, HOME_NET) are supplied in
[`so-install-runbook.md`](../so-install-runbook.md). The ISO Source &
Verification values in that runbook are already filled.

---

## A1 — Verify SO 3.1 ISO checksum + GPG signature ([#163](https://github.com/voltron-1/UIW-CDPv2/issues/163))

Pre-staged from `reference/DOWNLOAD_AND_VERIFY_ISO.md` @ tag `3.1.0-20260528`.
Run on the workstation after the ISO download; paste real output into **Result**.

```bash
# 1. Import Security Onion's signing key
wget https://raw.githubusercontent.com/Security-Onion-Solutions/securityonion/3/main/KEYS -O - | gpg --import -

# 2. Fetch the detached signature (or use the local copy in reference/sigs/)
wget https://github.com/Security-Onion-Solutions/securityonion/raw/3/main/sigs/securityonion-3.1.0-20260528.iso.sig

# 3. Download the ISO
wget https://download.securityonion.net/file/securityonion/securityonion-3.1.0-20260528.iso

# 4. Verify the GPG signature
gpg --verify securityonion-3.1.0-20260528.iso.sig securityonion-3.1.0-20260528.iso

# 5. Confirm the SHA256 checksum
sha256sum securityonion-3.1.0-20260528.iso
```

**Expected — must match exactly:**
- `gpg --verify` → **"Good signature from 'Security Onion Solutions, LLC …'"**
- Primary key fingerprint: `C804 A93D 36BE 0C73 3EA1 9644 7C10 60B7 FE50 7013`
- SHA256: `62FAB57E247C843D6A04F0796D8162C732B65D82FC3E4A59D087135B9FD32912`

**Result:** ✅ Operator-attested (2026-07-05): ISO verified **before** install.
_Paste the actual `gpg --verify` + `sha256sum` transcript here if captured, to
complete the golden-rule-4 record._

---

## A2 — Install SO 3.1 Standalone + setup wizard ([#164](https://github.com/voltron-1/UIW-CDPv2/issues/164))

Depends on A1 verified **and** the Target Host / NIC Layout / HOME_NET values in
`so-install-runbook.md`.

- [x] Boot the verified ISO (installs Oracle Linux 9 + Security Onion together)
- [x] Setup wizard: choose **Standalone**
- [x] Assign the **monitor interface** (`bond0`/`ens224`) **distinct from the
      management interface** (`ens160`)
- [x] Set **HOME_NET** to the lab subnet CIDR(s) — `10.18.81.0/24`

**Result:** ✅ Installed on a VMware Workstation Pro VM (4 vCPU / 32 GB / 200 GB).
Management `ens160` = 192.168.126.128/24; monitor `bond0`(`ens224`); HOME_NET
10.18.81.0/24. **Caveat:** monitor NIC has no live traffic source yet.

---

## A3 — Validate grid provisioning ([#165](https://github.com/voltron-1/UIW-CDPv2/issues/165))

- [x] `sudo so-status` — all services green (host `cardinal-so`, 2026-07-05)
- [x] SOC console reachable over HTTPS (`https://192.168.126.128`); login works
      — operator-confirmed 2026-07-05
- [ ] Default **Zeek** and **Suricata** telemetry landing (SOC → Alerts / Hunt
      show events). Monitor NIC has no live source, so validated via
      `sudo so-test` — it replays sample pcaps from `/opt/samples/*` onto the
      monitor interface (`so-tcpreplay`) + injects a sample firewall log,
      generating Zeek/Suricata events. Full production SPAN wiring is deferred to
      Phase 2 / #167.

> **Decision (2026-07-05):** direct grid access over SSH is **deferred to
> Phase 4** — this WSL2 workstation can't route to the VM's VMware-NAT IP, and
> `so-*` commands need `sudo`. Phase 4 (P4.1) sets up a dedicated read-only ES
> service account for programmatic access the least-privilege way. Phase 1
> evidence is captured from operator-run output.

**`so-test` run (2026-07-05, screenshot `phase1-so-test.png`):** replayed sample
PCAPs at 10 Mbps **onto the monitor interface `bond0`** — 111,557 packets /
4,102 flows sent in 10.38 s; 55,748 successful, **0 failed**, 0 truncated,
0 retried; "Replay completed." This confirms traffic reached the monitor NIC.
**Next — confirm the sensors detected it:** check SOC → **Alerts** (Suricata) and
**Hunt** (Zeek) for events from this window; that indexed-events check is the
actual Gate 1 sensor criterion.

**Result:** ✅ `so-status` clean — all 23 containers `running` (screenshot
`phase1-so-status.png`): so-dockerregistry, so-elastalert, so-elastic-fleet,
so-elastic-fleet-package-registry (healthy), so-elasticsearch, so-influxdb
(healthy), so-kibana, so-kratos, so-logstash, so-nginx (healthy), so-postgres
(healthy), so-redis, so-sensoroni, so-soc, so-strelka-{backend,coordinator,
filestream,frontend,gatekeeper,manager}, so-suricata, so-telegraf, so-zeek
(healthy). Banner: "This onion is ready to make your adversaries cry!"
SOC-console HTTPS login operator-confirmed. _Remaining for A3 / Gate 1: get
sensor events (monitor NIC currently sees no traffic)._

**Screenshots** (save under `evidence/screenshots/`, reference by filename):
- `phase1-so-status.png` — ✅ captured (all containers running)
- `phase1-so-test.png` — ✅ captured (PCAP replay onto bond0, 0 failed)
- `phase1-soc-console-login.png` — _pending_
- `phase1-alerts-from-so-test.png` — _pending (Suricata/Zeek events from the replay)_
- `phase1-grid-view.png` — _pending_
- `phase1-hunt-zeek-suricata-events.png` — _pending_

---

## A4 — Record the five ES service accounts + `auth.sls` ([#166](https://github.com/voltron-1/UIW-CDPv2/issues/166))

`[CC]` records once the grid is up. These feed Phase 4's dedicated least-priv
accounts (each re-pointed component mirrors — never reuses — this pattern).

`auth.sls` location on the manager: `/opt/so/saltstack/local/pillar/elasticsearch/auth.sls`

| Account | Purpose (as documented by SO) |
|---|---|
| _pending_ | |
| _pending_ | |
| _pending_ | |
| _pending_ | |
| _pending_ | |

**Result:** _PENDING — also append the confirmed accounts to `integration-inventory.md`._

---

## Gate 1 sign-off

- [ ] `so-status` clean (A3)
- [ ] SOC console up (A3)
- [ ] SO sensors producing events into Elasticsearch (A3)
- [ ] Old ELK still running untouched in parallel (verify legacy stack unaffected)
- [ ] This evidence file complete; #163–#166 closed with evidence links

**Rollback:** the grid is standalone and additive — a Phase 1 failure touches
nothing on the legacy ELK stack. Rebuild or re-run setup.
