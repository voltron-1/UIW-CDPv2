# Parity results — <WINDOW_START> .. <WINDOW_END>

- **Target:** <TARGET> (on the monitored segment)
- **Activities:** <ACTIVITIES>
- **Legacy ELK live during run:** [ ] yes
- Both stacks queried for the **same window** above.

| Activity | Legacy ELK count | SO count | Δ (SO − ELK) | SO ≥ ELK? | Notes |
|---|---|---|---|---|---|
| portscan | | | | | Zeek notice/conn + Suricata |
| ssh | | | | | Zeek ssh + Suricata |

**Query hints**
- **Legacy ELK:** `logstash-security-*` on the old Elasticsearch — see
  `../../tests/anomaly_simulation/verify_detections.py` for the query shape.
- **Security Onion:** SOC → Hunt / Alerts, time range = the window above; count by
  `event.module:zeek` and `event.module:suricata`.

**Verdict:** SO ≥ ELK for every activity? [ ] yes → parity criterion met (A5).

Record deltas and any anomalies in `../../docs/migration/evidence/phase-2.md`
(A5 table) and `../../docs/migration/integration-inventory.md`.
