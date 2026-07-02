# Integration Inventory — ES/Kibana/Logstash Touchpoints

Every component that currently integrates with Elasticsearch, Kibana, or
Logstash directly must be listed here with its Security Onion 3.1 target
method. No component cuts over until its row is `Validated`.

Status values: `Not started` → `Mapped` → `Re-pointed` → `Validated`.

| Component | Current integration method | SO 3.1 target method | Breaking changes | Owner | Status |
|---|---|---|---|---|---|
| SOAR agent (Flask, HMAC-SHA256 endpoints) | | | | | Not started |
| HDI/self-critique orchestrator | | | | | Not started |
| Ollama local-LLM layer | | | | | Not started |
| SLO metrics collection | | | | | Not started |
| Sigma detection rules / CI pipeline | | | | | Not started |
| Kibana dashboards / saved objects | | | | | Not started |
| Logstash pipeline configs (legacy) | | | | | Not started |
| Filebeat shippers (legacy) | | | | | Not started |

Add rows as further touchpoints are discovered; do not delete rows — mark
retired components as such in the target-method column.
