# Phase 1 Evidence — Stand up the SO grid

**Milestone:** M2 / [#10](https://github.com/voltron-1/UIW-CDPv2/issues/10) ·
**Gate:** Gate 1 · **Started:** 2026-07-05 · **Status:** ⏳ In progress —
pre-flight staged; on-hardware steps pending hardware allocation.

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

**Result:** _PENDING — paste `gpg --verify` + `sha256sum` output here._

---

## A2 — Install SO 3.1 Standalone + setup wizard ([#164](https://github.com/voltron-1/UIW-CDPv2/issues/164))

Depends on A1 verified **and** the Target Host / NIC Layout / HOME_NET values in
`so-install-runbook.md`.

- [ ] Boot the verified ISO (installs Oracle Linux 9 + Security Onion together)
- [ ] Setup wizard: choose **Standalone**
- [ ] Assign the **monitor interface** (SPAN/mirror destination) **distinct from
      the management interface**
- [ ] Set **HOME_NET** to the lab subnet CIDR(s) from the runbook

**Result:** _PENDING — record chosen interfaces + HOME_NET as installed._

---

## A3 — Validate grid provisioning ([#165](https://github.com/voltron-1/UIW-CDPv2/issues/165))

- [ ] `sudo so-status` — all services green
- [ ] SOC console reachable over HTTPS; login works
- [ ] Default **Zeek** and **Suricata** telemetry landing (SOC → Grid, and the
      Hunt / Dashboards views show live events)

**Result:** _PENDING — paste `so-status` output; list screenshots below._

**Screenshots** (save under `evidence/screenshots/`, reference by filename):
- `phase1-so-status.png` — _pending_
- `phase1-soc-console-login.png` — _pending_
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
