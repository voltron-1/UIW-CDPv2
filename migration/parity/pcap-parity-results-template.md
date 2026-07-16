# PCAP-replay parity results — pcap: `<PCAP_NAME>`

The **same canonical pcap** replayed into each stack (deterministic — identical
packets in, so any delta is the pipeline, not activity variance).

| Stack | Replay mode | Window (UTC) | Zeek events | Suricata events | Total |
|---|---|---|---|---|---|
| Security Onion | `so-tcpreplay` | | | | |
| Legacy ELK | `tcpreplay` / `zeek -r` | | | | |

**Δ (SO − ELK):** ______  **SO ≥ ELK?** [ ] yes → parity criterion met (A5 / #171).

**Notes**
- Built with `capture_parity_pcap.sh`; replayed per stack with `replay_parity_pcap.sh`.
- If the pcap uses localhost/off-segment addresses, Suricata HOME_NET rules may not
  match — capture against a monitored-segment target for Suricata fidelity (Zeek
  `conn` volume is address-agnostic and still comparable).
- Record deltas + anomalies in `../../docs/migration/evidence/phase-2.md` (A5) and
  `../../docs/migration/integration-inventory.md`.
