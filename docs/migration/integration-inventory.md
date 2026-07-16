# Integration Inventory — ES/Kibana/Logstash Touchpoints

Every component that currently integrates with Elasticsearch, Kibana, or
Logstash directly must be listed here with its Security Onion 3.1 target
method. No component cuts over until its row is `Validated`.

Status values: `Not started` → `Mapped` → `Re-pointed` → `Validated`.

| Component | Current integration method | SO 3.1 target method | Breaking changes | Owner | Status |
|---|---|---|---|---|---|
| Flask SOAR Response Agent (`scripts/setup/ai_agent/agent_app.py`) | ES via `ES_HOST` env + basic auth (`ES_USER` defaults `logstash_internal`), bulk `_bulk` writes for `soar-actions-*`/`soc-audit-*`; TLS verified against `ES_CA` (`/certs/ca/ca.crt`). Kibana Cases API via `KIBANA_URL` (plain HTTP) + basic auth. Inbound `/alert` webhook HMAC-SHA256-signed (`x-elastic-signature`); outbound containment HMAC-signed to `hive_mind_broker`. | | | | Not started |
| HDI/self-critique orchestrator (Network Inspection spoke) | **No implementation found in this repo.** Referenced only in planning docs (this inventory, ADR-001, execution-runbook.md, work-breakdown.md); no `.py`/config exists. Re-pointing per Phase 4 assumes code that doesn't exist yet — flagged for Tommy. | | | | Not started |
| Ollama local-LLM layer | No direct ES/Kibana integration found; invoked from `agent_app.py`'s LLM path (gated by `LLM_ALLOW_HOSTED` + `sanitize_for_llm()`). | | | | Not started |
| `slo_metrics.py` (`scripts/setup/ai_agent/`) | ES via `ES_URL` env, basic auth defaulting to `elastic` superuser, **`verify=False` hardcoded (TLS verification disabled)**. Kibana Cases API via `KIBANA_URL` (plain HTTP), same creds. | | | | Not started |
| `weekly_ciso_report.py` (`scripts/setup/ai_agent/`) | ES via official `elasticsearch` client, `api_key` env (default is the literal placeholder string `"your_es_api_key"`), **`verify_certs=False`**. No Kibana connection. LLM: direct POST to `api.openai.com` with no `LLM_ALLOW_HOSTED` gate or sanitization — no egress governance, unlike `agent_app.py`. | | | | Not started |
| Kibana dashboards / saved objects (`configs/server/*.ndjson`) | Provisioned via `deploy_soc_presentation.sh` — hardcoded `http://localhost:5601`, hardcoded creds `elastic`/`changeme`, `_saved_objects/_import`. `export_data_views.py`/`push_data_views.sh` hit `_saved_objects/_export` with **no auth at all**. `populate_dashboards.py` writes to ES over plain HTTP, no auth. | | | | Not started |
| Sigma detection rules / CI pipeline | Rules staged in `detections/`; legacy CI target unclear pending Phase 3 four-gate retarget (`migration/ci/`). | | | | Not started |
| Logstash pipeline configs (legacy) (`configs/logstash.conf`, `scripts/setup/configs/logstash/logstash.conf`) | `beats` input on 5044 (plaintext) + `http` input on 5514; ES output to `https://elasticsearch:9200` as `elastic` superuser, TLS verified against a pinned CA. Also posts to `ntfy.sh` on critical-threat tag. | | | | Not started |
| Filebeat shippers (legacy) (`configs/server/filebeat.yml`, `configs/network/filebeat.yml`) | Reads `/storage/PCAP/zeek_logs/*.log`; ships to Logstash beats input over **plain TCP, no TLS, no auth**. | | | | Not started |

Add rows as further touchpoints are discovered; do not delete rows — mark
retired components as such in the target-method column.
