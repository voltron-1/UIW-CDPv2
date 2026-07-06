# Phase 2 Parity Harness

Fixed-activity generator for the Gate 2 **parity check** (P2.5 / [#171](https://github.com/voltron-1/UIW-CDPv2/issues/171)):
run the same benign activity on the monitored segment so **both** Security Onion
and the legacy ELK stack observe it, then confirm **SO ≥ ELK** for the window.

It **reuses** the sims in [`../../tests/anomaly_simulation/`](../../tests/anomaly_simulation/)
(`sim_portscan.sh`, `sim_brute_ssh.sh`) — it does not reinvent the activity. It
pins the target to the monitored segment, times the window in UTC, and writes a
results file from `parity-results-template.md`.

## Prerequisites

- **Run from a host on the monitored segment, targeting another host on that same
  segment.** Loopback / off-segment traffic never crosses the monitor NIC, so SO
  would see nothing — the script refuses a `localhost`/`127.*` target.
- **A1 / [#167](https://github.com/voltron-1/UIW-CDPv2/issues/167) done:** the
  monitor NIC (`ens224`) actually receives that segment's traffic (promiscuous
  vSwitch / bridged mirror), and HOME_NET matches the monitored segment.
- **Legacy ELK live** (`voltron-1/Suburban_SOC`) — parity compares against it.
- Sim host bins: `nmap`, `sshpass` (see the sims' README).

## Usage

```bash
PARITY_TARGET=10.18.81.50 ./run_parity_window.sh
# optional overrides:
#   PARITY_ACTIVITIES="portscan ssh malware"   # default: "portscan ssh"
#   SIMS_DIR=/path/to/tests/anomaly_simulation
#   RESULTS_DIR=/path/to/output
```

It prints the exact UTC window and writes `results/parity-<stamp>.md`.

## Then (A5 / #171)

1. Count events for that window in **both** stacks (ELK `logstash-security-*`; SO
   Hunt/Alerts by `event.module:zeek` / `event.module:suricata`).
2. Fill the results file and copy the table into
   [`../../docs/migration/evidence/phase-2.md`](../../docs/migration/evidence/phase-2.md) (A5).
3. Confirm **SO ≥ ELK** per activity. Old ELK must stay live during the run.

## Not automated here (by design)

Querying **SO's** Elasticsearch is **deferred to Phase 4** (P4.1 provisions a
read-only least-privilege ES account). Until then the SO-side counts are read
from the SOC console. `results/` is runtime output and is git-ignored.
