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

Run the fixed activity set (`migration/parity/run_parity_window.sh`) on the
monitored segment while **both** SO and legacy ELK are live; count events per
activity in the same window and confirm **SO ≥ ELK**. Log deltas here and in
`integration-inventory.md`.

| Activity | Window (UTC) | Legacy ELK count | SO count | Δ | SO ≥ ELK? |
|---|---|---|---|---|---|
| Port scan (`sim_portscan.sh`) | _pending_ | | | | |
| SSH brute (`sim_brute_ssh.sh`) | _pending_ | | | | |

**Result:** _PENDING — attach the completed parity results file
(`migration/parity/parity-results-template.md` copy)._

---

## A6 — Re-measure ingest lag ([#172](https://github.com/voltron-1/UIW-CDPv2/issues/172))

Measure SO end-to-end lag (`@timestamp` − event time) on a known event class;
compare to the legacy breach (**~23,662 s vs 300 s SLO**). The delta is capstone
evidence.

| Metric | Legacy ELK | Security Onion |
|---|---|---|
| Median ingest lag (event class: _TBD_) | ~23,662 s (breach) | _pending_ |
| Within 300 s SLO? | ✗ | _pending_ |

**Result:** _PENDING — record method + measured lag._

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
