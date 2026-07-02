# ADR-001: Migrate UIW-CDP from hand-built ELK stack to Security Onion 3.1

- **Status:** Proposed
- **Date:** 2026-07-02
- **Deciders:** Tommy Lammers (Lead Architect), Sterling Garnett (Security Analyst), Ishmael Pendleton (Network Engineer)
- **Tracking:** Seeds the ADR log required by issue #150 (D-38)

## Context

UIW-CDP currently runs a hand-built detection stack: Zeek → Filebeat → Logstash →
Elasticsearch 8.x → Kibana, plus original capstone components — a Python Flask
SOAR agent with HMAC-SHA256-authenticated endpoints, an HDI/self-critique
orchestrator, and an Ollama local-LLM analysis layer.

Maintaining the base pipeline (ingest plumbing, index templates, upgrades,
inter-service TLS/auth) consumes engineering time that produces no original
capstone value. Security Onion 3.1 (pinned reference tag `3.1.0-20260528`, ISO
install, Standalone deployment on dedicated hardware) provides that entire base
platform as a maintained, Salt-managed distribution, including a Detections
module with native Sigma rule-repo support.

## Decision

Adopt Security Onion 3.1 as the base detection platform and re-integrate the
capstone's original components against SO's Elasticsearch surface. The
hand-built Zeek/Filebeat/Logstash/ES/Kibana stack is retired. Integration work
is staged under `migration/` and follows the five-phase plan in
`docs/migration/README.md`.

Each re-integrated component (SOAR agent, orchestrator, SLO metrics) connects
via a **dedicated least-privilege service account** on SO's Elasticsearch — not
a borrowed built-in credential such as `so_elastic`.

## Free vs. Pro boundary

Security Onion Pro features we will **not** use: MCP Server, External API,
Reports, and Onion AI. Our Ollama local-LLM layer, Flask SOAR agent, and
custom reporting are the free-tier equivalents of those capabilities and
constitute the capstone's original contribution. This boundary is deliberate:
the project must demonstrate that an AI-assisted SOC layer can be built on the
free tier, and nothing in `migration/` may take a dependency on a Pro-only
surface.

## License posture

The reference repo's `LICENSE` is the **Elastic License 2.0 (ELv2)** — a
source-available license, **not** GPL and not OSI open source. Key limitations:
no providing the software to third parties as a hosted/managed service, no
circumventing license-key functionality, no removing licensing notices. Our
use — running SO internally for a university capstone and writing integrations
against its APIs — is within the grant. The `reference/` clone is gitignored
and never redistributed through this repo.

## Consequences

- **Positive:** platform maintenance burden moves to Security Onion upstream;
  the team focuses on original work (SOAR, orchestrator, LLM triage, SLOs);
  Sigma rules gain a native deploy path via the Detections module
  (`/nsm/rules/custom-local-repos/local-sigma`).
- **Negative / cost:** every component that touched ES/Kibana/Logstash directly
  must be re-pointed and re-tested (tracked in
  `docs/migration/integration-inventory.md`); ECS field mappings differ from
  our legacy Logstash output and all Sigma rules need field-mapping triage;
  the team takes on Salt/pillar literacy to configure SO correctly.
- **Risks:** free-tier boundary creep (mitigated by this ADR's explicit Pro
  list); credential sprawl on SO's ES (mitigated by the dedicated
  service-account rule above).
