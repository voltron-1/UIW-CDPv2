# Phase 2 Parity Harness

Tooling for the Gate 2 **parity check** (P2.5 / [#171](https://github.com/voltron-1/UIW-CDPv2/issues/171)):
generate the same simulated activity, get it to **both** the Security Onion and
legacy ELK sensors, and confirm **SO ≥ ELK** for the window.

> Dev environment — traffic is **simulated by design** (`so-test`/`tcpreplay` or
> the `../../tests/anomaly_simulation/` sims). There is no production feed. The
> two methods below differ only in *how* the simulated activity reaches the sensors.

## Two injection methods

| | **PCAP replay** (recommended for parity) | **Live flows on a segment** |
|---|---|---|
| Script | `capture_parity_pcap.sh` + `replay_parity_pcap.sh` | `run_parity_window.sh` |
| How | Capture the sims once → replay the **identical pcap** into each sensor | Run the sims live on a promiscuous segment both sensors watch |
| Determinism | **High** — same bytes into both stacks; any delta is the pipeline | Lower — each sensor sees its own copy of a live run |
| VMware setup | Minimal — replay onto each monitor NIC; no shared segment needed | Needs a promiscuous vSwitch/segment both sensors observe |
| Reaches both stacks | Yes — replay the same file on each host | Only if both sensors are on the same monitored segment |
| Suricata fidelity | Depends on captured addresses (see note) | Real segment addresses |
| Best for | **Parity** (A5), ECS spot-check (A3), ingest lag (A6) | Realistic end-to-end when a shared segment exists |

Both reuse the existing sims (`sim_portscan.sh`, `sim_brute_ssh.sh`) — neither
reinvents the activity.

## Method A — PCAP replay (deterministic)

```bash
# 1. Capture the canonical activity ONCE (anywhere the sims run; even lo/localhost).
#    For Suricata HOME_NET fidelity, target a host on the monitored segment.
PARITY_TARGET=10.18.81.50 CAPTURE_IFACE=eth0 ./capture_parity_pcap.sh
#    -> writes pcaps/parity-<stamp>.pcap

# 2. Replay the SAME pcap into each stack, on that stack's sensor host:
#    Security Onion grid:
REPLAY_MODE=so-tcpreplay STACK_LABEL=SO  PCAP=pcaps/parity-<stamp>.pcap ./replay_parity_pcap.sh
#    Legacy ELK sensor:
REPLAY_MODE=tcpreplay REPLAY_IFACE=<mon> STACK_LABEL=ELK PCAP=pcaps/parity-<stamp>.pcap ./replay_parity_pcap.sh
#    (legacy alternative: REPLAY_MODE=zeek — `zeek -r <pcap>` offline)

# 3. Count events per stack for each printed window; fill pcap-parity-results-template.md.
```

**Address note:** a pcap captured against localhost/off-segment still gives a valid
**Zeek `conn` volume** comparison, but Suricata rules keyed to HOME_NET
(`10.18.81.0/24`) won't match loopback addresses — capture against a
monitored-segment target for Suricata fidelity.

## Method B — Live flows on a segment

```bash
PARITY_TARGET=10.18.81.50 ./run_parity_window.sh
# prints the UTC window and writes results/parity-<stamp>.md
```
Requires a promiscuous VMware segment both sensors observe (refuses a localhost
target — loopback never crosses a monitor NIC).

## Prerequisites

- Sim host bins: `nmap`, `sshpass`; capture needs `tcpdump`; replay needs
  `tcpreplay` (or `so-tcpreplay` on the grid, or `zeek` for offline).
- **Legacy ELK live** (`voltron-1/Suburban_SOC`) — parity compares against it.
- For Method B / live network events: A1 / [#167](https://github.com/voltron-1/UIW-CDPv2/issues/167)
  (monitored segment reaches the NICs) and HOME_NET aligned with that segment.

## Then (A5 / #171)

Count the window in **both** stacks (SO: Hunt/Alerts by `event.module:zeek` /
`event.module:suricata`; ELK: `logstash-security-*`), confirm **SO ≥ ELK**, and
copy the table into [`../../docs/migration/evidence/phase-2.md`](../../docs/migration/evidence/phase-2.md).

## Not automated here (by design)

Querying **SO's** Elasticsearch is **deferred to Phase 4** (P4.1 provisions a
read-only least-privilege ES account). Until then SO-side counts are read from the
SOC console. `results/`, `pcaps/`, and `.env` are git-ignored.
