# Phase 2 Evidence — Telemetry cutover & parity

**Milestone:** M3 / [#11](https://github.com/voltron-1/UIW-CDPv2/issues/11) ·
**Gate:** Gate 2 · **Status:** ⏳ Not started — scaffold prepared; awaiting real
traffic on the monitor NIC (Track A step A1 / #167).

> Golden rule 4: every gate produces evidence here — command output, screenshots
> by filename, issue links. Fill each step's **Result** as it is executed; nothing
> is fabricated ahead of time. Plan: [`plans/20260705-so-migration-phase2-kickoff.md`](../../../plans/20260705-so-migration-phase2-kickoff.md).

**Gate 2 exit criteria** ([#11](https://github.com/voltron-1/UIW-CDPv2/issues/11),
verbatim): SO telemetry ≥ old-ELK telemetry for the parity window · ECS confirmed ·
heartbeat visible · ingest lag within SLO · **old ELK still live**.

**Prerequisites carried in from Phase 1:**
- **Traffic is simulated by design** — this is a development environment with no
  production feed, and none is expected. A1 gets simulated traffic to the sensor
  on `bond0`/`ens224`: replay pcaps onto the interface (`so-test`/`tcpreplay`) or
  run the sims on a promiscuous segment the NIC observes.
- **HOME_NET** `10.18.81.0/24` must equal the segment the sims run on (management
  is `192.168.126.0/24`) — resolve before/at A1.
- **Legacy ELK** (`voltron-1/Suburban_SOC`) must be **running** for the A5 parity
  comparison.
- Lab endpoints (≥1 Windows w/ Sysmon, ≥1 Linux) for A2 enrollment.

---

## A1 — Get simulated traffic to the sensor ([#167](https://github.com/voltron-1/UIW-CDPv2/issues/167))

Dev environment — traffic is simulated, not real. Two workable injection methods:
replay pcaps onto `ens224` (`so-test`/`tcpreplay`), or run the sims on a
promiscuous segment the monitor NIC observes (better exercises the capture path,
and lets the legacy ELK sensor see the same activity for A5 parity).

- [ ] Chosen injection method produces flows the sensor captures
- [ ] HOME_NET aligned with the segment the sims run on
- [ ] Simulated benign activity appears in SOC → Hunt as **Zeek** and **Suricata** events

**Result:** _PENDING — record the injection method and paste a Hunt screenshot of
the simulated events (`phase2-sim-traffic-hunt.png`)._

---

## A2 — Enroll endpoints via Elastic Agent / Fleet ([#168](https://github.com/voltron-1/UIW-CDPv2/issues/168))

- [ ] ≥1 Windows endpoint enrolled (Sysmon: process + command line, PowerShell, auth)
- [ ] ≥1 Linux endpoint enrolled (process + auth)
- [ ] Host events landing in Elasticsearch (satisfies #6 / #125 / D-13 natively)

**Result:** _PENDING — list enrolled hosts + Fleet screenshot (`phase2-fleet-agents.png`)._

---

## A3 — Spot-check ECS normalization ([#169](https://github.com/voltron-1/UIW-CDPv2/issues/169))

Confirm a Zeek `conn` event and a Windows process event carry **ECS field names**.
Verifies SO does natively what #123 / D-11 asked us to build.

| Sample event | ECS fields to confirm present |
|---|---|
| Zeek `conn` | `source.ip`, `source.port`, `destination.ip`, `destination.port`, `network.transport`, `event.dataset` |
| Windows process | `process.name`, `process.command_line`, `process.pid`, `user.name`, `host.name`, `event.module` |

**Result:** _PENDING — paste the two events' field views (`phase2-ecs-zeek-conn.png`, `phase2-ecs-win-process.png`)._

---

## A4 — Sensor/agent heartbeat ([#170](https://github.com/voltron-1/UIW-CDPv2/issues/170))

- [ ] SOC → Grid shows sensor + agent health
- [ ] Stop a shipper/agent → native dead-shipper alarm fires (satisfies #126 / D-14)

**Result:** _PENDING — Grid screenshot + dead-shipper alarm (`phase2-grid-health.png`, `phase2-dead-shipper-alarm.png`)._

---

## A5 — Parity check vs. legacy ELK ([#171](https://github.com/voltron-1/UIW-CDPv2/issues/171))

Confirm **SO ≥ ELK** while both stacks are live. Two harness methods
(`migration/parity/`): **pcap replay** (recommended — capture the sims once, replay
the identical pcap into each sensor for a deterministic comparison) or **live
flows** on a shared promiscuous segment. Log deltas here and in
`integration-inventory.md`.

| Stack | Method | Window (UTC) | Zeek events | Suricata events | Total |
|---|---|---|---|---|---|
| Legacy ELK | _pending_ | _pending_ | | | |
| Security Onion | _pending_ | _pending_ | | | |

**Δ (SO − ELK):** _pending_ · **SO ≥ ELK?** _pending_

**Result:** _PENDING — attach the completed results file (`pcap-parity-results-template.md`
or `parity-results-template.md` copy)._

---

## A6 — Re-measure ingest lag ([#172](https://github.com/voltron-1/UIW-CDPv2/issues/172))

Measure SO end-to-end ingest lag on a known event class; compare to the legacy
breach (**~23,662 s vs 300 s SLO**). The delta is capstone evidence.

**Event class (defined up front):**
- **Primary — Zeek `conn`** (`event.module:zeek` / `event.dataset:conn`) from the
  A1 sensor path. Same network pipeline Phase 2 validates, same class the legacy
  breach was measured against, and A1 traffic generates it continuously (good
  sample size).
- **Secondary (diagnostic) — an Elastic Agent process event** (`event.module`
  `windows`/`system`) via Fleet — a *different* pipeline (mgmt network → Fleet →
  ES), so lag can be compared per-pipeline, not just in aggregate.

**Formula (ECS, decomposed so a breach is diagnosable):**
- end-to-end = `event.ingested − @timestamp`  ← **headline vs the 300 s SLO**
- collection = `event.created − @timestamp`  (source → shipper/agent)
- index = `event.ingested − event.created`  (shipper → indexed in ES)

`event.ingested` is stamped by the ES ingest pipeline at index time (best
"queryable in the store" proxy); `@timestamp` is when the event occurred.

**Method (repeatable) — helper: [`migration/parity/ingest_lag.py`](../../../migration/parity/ingest_lag.py):**
1. In SOC → Hunt (or Kibana Discover) scope to the event class over a fixed recent
   window (e.g. the 15 min after an A1 injection). Add `@timestamp`,
   `event.created`, `event.ingested` as columns.
2. Download/export the result set as NDJSON.
3. `python3 migration/parity/ingest_lag.py --format md <export>.ndjson` →
   emits the Security-Onion column below and exits **0 = within SLO / 1 = breach**
   (median AND p95 must fit). Reports collection/index legs too, so a breach
   points at collection vs. transport.
4. **Fallback** (if `event.ingested` isn't exposed in the console): note UTC
   `T_inject` at A1 start, watch Hunt for first appearance `T_visible`; lag ≈
   `T_visible − T_inject` (coarse single-sample upper bound — record both).
5. **Phase-4 upgrade:** once P4.1 provisions the read-only ES account, pipe an ES
   query's `_source` lines straight into `ingest_lag.py` for large-sample,
   automated median/p95 — no manual export.

Direct SO ES querying stays **deferred to Phase 4** (P4.1); until then A6 reads
from the console export, consistent with `migration/parity/README.md`.

| Metric | Legacy ELK | Security Onion |
|---|---|---|
| Median end-to-end lag (event class: Zeek `conn`) | ~23,662 s (breach) | _pending_ |
| p95 end-to-end lag | — | _pending_ |
| Max end-to-end lag | — | _pending_ |
| Within 300 s SLO? | ✗ | _pending_ |

**Result:** _PENDING — run the method above; paste the `--format md` table and note
the exit-code verdict + the event class/window used._

---

## Gate 2 sign-off

- [ ] SO telemetry ≥ old-ELK telemetry for the parity window (A5)
- [ ] ECS confirmed (A3)
- [ ] Heartbeat visible (A4)
- [ ] Ingest lag within SLO (A6)
- [ ] Old ELK still live (parallel-run intact)
- [ ] #167–#172 closed with evidence links

**Rollback:** additive — old ELK untouched. On failure, fix the
sensor/agent/interface and re-validate; never proceed to detection work (Phase 3)
on a grid that isn't seeing data.
