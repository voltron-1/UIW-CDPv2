# SLO Metrics Re-integration

Re-integration goal: re-point SLO metrics collection (detection latency,
pipeline health, triage SLOs) from the legacy self-managed Elasticsearch 8.x
to Security Onion 3.1's Elasticsearch surface.

Access is via a **dedicated least-privilege service account** created for
metrics collection — read-only, scoped to the monitoring/metrics indices —
**not** a borrowed built-in credential such as `so_elastic`. See the account
pattern in `reference/salt/elasticsearch/auth.sls`
(`docs/migration/salt-map.md`) and track progress in
`docs/migration/integration-inventory.md`.
