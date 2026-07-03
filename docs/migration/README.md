# Security Onion 3.1 Migration

Migration of UIW-CDP from the hand-built Zeek → Filebeat → Logstash →
Elasticsearch 8.x → Kibana stack to **Security Onion 3.1** (ISO install,
Standalone deployment on dedicated hardware). Decision record:
[ADR-001](../adr/ADR-001-security-onion-migration.md).

## Pinned reference

Upstream source is cloned read-only at `reference/` (gitignored, never
committed):

- Repo: <https://github.com/Security-Onion-Solutions/securityonion>
- **Pinned tag: `3.1.0-20260528`**
- License: Elastic License 2.0 (see ADR-001, License posture)

All salt/pillar citations in [salt-map.md](salt-map.md) refer to this tag.

## Team roles

| Role | Owner |
|---|---|
| Lead Architect | Tommy |
| Security Analyst | Sterling Garnett |
| Network Engineer | Ishmael Pendleton |

## Five-phase plan

1. **Foundation** — pin the reference tag, scaffold `migration/`, map SO's
   salt/pillar surface, ADR-001, integration inventory. *(this PR)*
2. **Platform stand-up** — ISO install of SO 3.1 Standalone on dedicated
   hardware; Zeek interface + BPF config; baseline health checks.
3. **Detections migration** — Sigma rules through ECS field-mapping triage,
   staged in `detections/`, deployed to
   `/nsm/rules/custom-local-repos/local-sigma`; four-gate CI retarget
   (`migration/ci/`).
4. **Integration re-point** — SOAR agent, HDI/self-critique orchestrator, and
   SLO metrics re-integrated against SO's Elasticsearch surface using
   dedicated least-privilege service accounts (`migration/integrations/`).
5. **Validation & cutover** — re-emulation regression against migrated
   detections, purple-team coverage validation, decommission of the legacy
   stack, close-out of the migration issue set.

## Working areas

- `docs/migration/work-breakdown.md` — the five phases decomposed into
  Phase → Work Package → Task, with per-task validation checks, dependencies,
  and linked issues.
- `docs/migration/integration-inventory.md` — every component that touches
  ES/Kibana/Logstash directly, with its SO 3.1 target method.
- `docs/migration/salt-map.md` — where the relevant config lives in
  `reference/salt/` and `reference/pillar/`.
- `migration/` — staging for detections, integrations, and CI retarget.
