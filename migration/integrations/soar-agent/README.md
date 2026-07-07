# SOAR Agent Re-integration

Re-integration goal: re-point the Flask SOAR agent (HMAC-SHA256-authenticated
endpoints) from the legacy self-managed Elasticsearch 9.3.2 to Security Onion
3.1's Elasticsearch surface.

Access is via a **dedicated least-privilege service account** created for the
SOAR agent — scoped to only the indices/actions it needs — **not** a borrowed
built-in credential such as `so_elastic`. See the account pattern in
`reference/salt/elasticsearch/auth.sls` (`docs/migration/salt-map.md`) and
track progress in `docs/migration/integration-inventory.md`.
