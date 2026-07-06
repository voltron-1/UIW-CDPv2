# Plan: Security Onion Migration — Phase 2 Kickoff

Date: 2026-07-05 · Owner: Tommy · Board: GitHub Project #13 ("CARDINAL — SO 3.1 Migration")

References: [execution-runbook.md](../docs/migration/execution-runbook.md) (Phase 2) ·
[work-breakdown.md](../docs/migration/work-breakdown.md) ·
[board-structure-proposal.md](../docs/migration/board-structure-proposal.md) ·
[integration-inventory.md](../docs/migration/integration-inventory.md) ·
[evidence/phase-1.md](../docs/migration/evidence/phase-1.md)

## §1 Current State

- **Phase 1 complete — Gate 1 met (2026-07-05, PR #198 merged).** SO Standalone
  grid `cardinal-so` healthy on a VMware Workstation VM (12 vCPU / 32 GB / 200 GB);
  `so-status` green, SOC console up, 235 Suricata alerts proven via `so-test`.
  #160, #163–#166 closed.
- **Next gate: Gate 2.** Phase 2 proves SO's native telemetry matches or beats the
  legacy ELK pipeline, in ECS, with acceptable ingest lag — while the old stack
  stays live (golden rule 1, parallel-run).
- **Entry step:** get simulated traffic to the sensor on `bond0`/`ens224` (#167).
  This is a **development environment — all sensor traffic is simulated**
  (`so-test`/`tcpreplay` or the sim scripts); there is no production feed and none
  is expected. Phase 1 used `so-test` replay; Phase 2 formalizes the injection
  method so both SO and legacy ELK observe the same simulated activity.
- **Standing prerequisite for parity:** the legacy ELK stack (sibling repo
  `voltron-1/Suburban_SOC`) must be **running concurrently** — the Gate 2 parity
  check (#171) compares SO against it. Confirm it is up before P2.5.

Goal (runbook): *"the data SO collects natively matches or beats what the old
pipeline collected, in ECS."*

## §2 Track A — Critical Path (Gate 2)

Milestone M3 / [#11](https://github.com/voltron-1/UIW-CDPv2/issues/11). Every step
logs to its issue **and** to `docs/migration/evidence/phase-2.md` (new).

| Step | Issue | Owner | Entry | Exit |
|---|---|---|---|---|
| **A1 — Get simulated traffic to the sensor** | [#167](https://github.com/voltron-1/UIW-CDPv2/issues/167) `[P2.1]` | `[HUMAN]` + Ishmael | Grid up | Simulated activity reaches `ens224` and appears in Hunt as Zeek + Suricata events. **Dev methods:** replay pcaps onto `ens224` (`so-test`/`tcpreplay`), or run the sims on a VMware segment with **promiscuous mode enabled** that the NIC observes (needed for A5 parity, so legacy ELK's sensor sees the same flows). Resolve HOME_NET (`10.18.81.0/24`) to match the segment the sims run on (management is `192.168.126.0/24`). |
| **A2 — Enroll endpoints (Elastic Agent/Fleet)** | [#168](https://github.com/voltron-1/UIW-CDPv2/issues/168) `[P2.2]` | `[HUMAN]` | Grid up (parallel to A1) | ≥1 Windows (Sysmon: process + command line, PowerShell, auth) and ≥1 Linux endpoint enrolled via Fleet; host events landing in ES. Satisfies #6 / #125 (D-13) natively. |
| **A3 — Spot-check ECS normalization** | [#169](https://github.com/voltron-1/UIW-CDPv2/issues/169) `[P2.3]` | `[HUMAN]` | A1 + A2 producing events | A Zeek `conn` event and a Windows process event show **ECS field names** (`source.ip`, `destination.ip`, `process.command_line`, `host.name`, …). Verifies #123 (D-11) is native. |
| **A4 — Sensor/agent heartbeat** | [#170](https://github.com/voltron-1/UIW-CDPv2/issues/170) `[P2.4]` | `[HUMAN]` | A1 + A2 | SOC → Grid shows sensor + agent health; stop a shipper and confirm the native dead-shipper alarm fires (#126 / D-14). |
| **A5 — Parity check vs. legacy ELK** | [#171](https://github.com/voltron-1/UIW-CDPv2/issues/171) `[P2.5]` | `[HUMAN]` | A1–A4; **legacy ELK live** | For a fixed window, run the same activity on the monitored segment and confirm SO sees **at least** what old-ELK saw; log deltas in `integration-inventory.md`. |
| **A6 — Re-measure ingest lag** | [#172](https://github.com/voltron-1/UIW-CDPv2/issues/172) `[P2.6]` | `[HUMAN]` runs / `[CC]` records | A1 producing events | Measure SO end-to-end lag (event time → indexed `@timestamp`) on the same event class; compare to the old breach (~23,662 s vs 300 s SLO). The delta is capstone evidence. |

**Gate 2** ([#11](https://github.com/voltron-1/UIW-CDPv2/issues/11), verbatim):
SO telemetry ≥ old-ELK telemetry for the parity window · ECS confirmed ·
heartbeat visible · ingest lag within SLO · **old ELK still live**.

**Evidence** `docs/migration/evidence/phase-2.md` (new): live-traffic Hunt
screenshots, Fleet enrollment list, ECS field screenshots for the two sample
events, heartbeat + dead-shipper-alarm screenshots, the parity table (SO vs ELK
counts per activity), and the ingest-lag before/after. **Rollback:** additive —
old ELK untouched; on failure, fix the sensor/agent/interface and re-validate,
never proceed to detection work on a grid that isn't seeing data.

## §3 Track B — Prep, Not Grid-Blocked (start now)

1. **Scaffold `evidence/phase-2.md`** — the A1–A6 structure with expected outputs,
   mirroring `phase-1.md`.
2. **Parity-test harness (reuse, don't rebuild)** — adopt the existing
   `tests/anomaly_simulation/` sims as the fixed parity activity set:
   `sim_portscan.sh` (Nmap sweep) and `sim_brute_ssh.sh` (SSH login), driven from
   `run_all.sh`. Document that they must run **on the monitored segment** so both
   SO and legacy ELK observe the same activity; note `verify_detections.py` as the
   pass/fail checker.
3. **ECS spot-check checklist (A3)** — from the pinned `reference/` clone + ECS,
   pre-list the exact ECS field names expected on a Zeek `conn` event and a Windows
   process event, so the on-grid check is a comparison, not a hunt.
4. **Ingest-lag measurement procedure (A6)** — a repeatable method: inject/observe
   a timestamped event, compute `@timestamp − event.created`; define the event
   class and the SLO (300 s) up front.
5. **Pre-stage `integration-inventory.md`** — add the ECS-mapping / parity-delta
   rows Track A will fill.

## §4 Sequencing

- **A1 (SPAN) is the network-events gate** — nothing network-side flows until real
  traffic reaches `ens224`. **A2 (endpoints) runs in parallel** — host telemetry
  goes over the management network via Fleet, independent of the monitor NIC.
- A3/A4 need A1+A2 producing events. **A5 (parity) additionally requires the legacy
  ELK stack running.** A6 needs A1 flowing.
- All Track B items start today, independent of the grid.

## §5 Conventions

- Evidence to each issue + `evidence/phase-2.md`; `git push` follows every commit;
  every new issue → Project #13; merges require Tommy's explicit approval.
- Direct grid access over SSH remains **deferred to Phase 4** (P4.1 least-priv ES
  account) — Phase 2 evidence is operator-run output, as in Phase 1.

## §6 Risks

- **Simulated-traffic method** — dev environment, no production SPAN by design;
  pick and document the injection method (replay onto the NIC vs. flows on a
  promiscuous segment). Flows-on-a-segment is required for A5 parity so both
  stacks' sensors see the same activity.
- **Endpoints must exist** — A2 needs at least one Windows (with Sysmon) and one
  Linux lab endpoint; build them if absent.
- **Legacy ELK availability** — A5 parity is impossible if `Suburban_SOC` isn't
  running; confirm/stand it up before P2.5.
- **HOME_NET mismatch** — `10.18.81.0/24` vs management `192.168.126.0/24`; resolve
  before A1 or the sensors/HOME_NET won't align.
- **200 GB disk** — limits the parity window and retention; keep windows short.
