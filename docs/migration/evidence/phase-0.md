# Phase 0 Evidence

## 0.6 — Freeze checkpoint / D-37

**Snapshot mechanism:** Elasticsearch Snapshot Lifecycle Management (SLM), not
a VM snapshot. The legacy ELK stack runs in a separate sibling repo,
`voltron-1/Suburban_SOC` (local checkout: `~/projects/Suburban-SOC`), which
already had a filesystem snapshot repository and daily SLM policy configured
(`configs/elasticsearch/apply-lifecycle.sh`, `ilm/snapshot-repository.json`,
`ilm/slm-policy.json`) — this checkpoint uses that existing mechanism rather
than building a new one.

**Action taken (2026-07-03, this session):**
1. Brought up only the containers needed for the checkpoint —
   `docker compose up -d elasticsearch lifecycle` in
   `Suburban-SOC/scripts/setup/` (auto-resolves the `setup` cert-gen
   dependency). Kibana, Logstash, the AI agent, and the hive-mind broker were
   left down — out of scope for an ES-only snapshot.
2. `soc_lifecycle` re-applied (idempotent) the snapshot repo, SLM policy, ILM
   policies, and index templates — all four steps returned HTTP 200.
3. Triggered an on-demand snapshot: `apply-lifecycle.sh --snapshot-now` →
   `POST _slm/policy/suburban-soc-daily-snapshots/_execute` → HTTP 200.

**Result:**

| Field | Value |
|---|---|
| Snapshot | `suburban-soc-snap-2026.07.03-jv7kixdrrw-gvzsn4l3tjq` |
| Repository | `suburban-soc-snapshots` (fs, location `suburban-soc`) |
| State | `SUCCESS` |
| Shards | 30 / 30 successful, 0 failed |
| Indices captured | 30 (`logstash-security-*`, `soar-actions-*`, `soc-controls`, `soc-deploys`, `soc-audit-*` and their data streams) |
| Timestamp | 2026-07-03T01:56:32Z |

Nine earlier nightly snapshots (2026-06-11 through 2026-06-29) are also
present in the repository, all `SUCCESS` — the SLM policy has been running
reliably; this checkpoint is not the first evidence of restorability, just
the first one taken deliberately as a migration freeze point.

**Restorability — actually verified, not assumed:**
- Live `soc-controls` index: 35 documents (`_count`)
- Restored `soc-controls` from the above snapshot into a scratch index
  (`rename_pattern`/`rename_replacement`, so the live index was never
  touched): `POST _snapshot/suburban-soc-snapshots/<snapshot>/_restore` →
  restored index also shows 35 documents — exact match
- Scratch index deleted after verification (`DELETE
  restore-verify-soc-controls` → confirmed gone, HTTP 404 on re-check)

**Per the runbook:** this snapshot is the honest version of issue **#149** —
not an in-place ELK→OS migration (which #149 originally scoped), but the
rollback point before the parallel SO grid is built. #149 should be closed as
superseded once this is reviewed, per Phase 5's resolution of the
decision-gated set.

**Note:** the `elasticsearch` container in Suburban-SOC is still running as
of this checkpoint (only `zeek-host-capture` was running before this
session). Left up in case further inspection is wanted — say the word if it
should be stopped to return to the prior state.
