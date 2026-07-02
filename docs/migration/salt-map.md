# Salt/Pillar Map — Security Onion 3.1 (`3.1.0-20260528`)

Where the config surfaces relevant to our migration live in the read-only
reference clone (`reference/`, gitignored). Paths are relative to
`reference/`. Do not modify anything under `reference/`.

## 1. Elasticsearch auth / TLS

| Path | What it is |
|---|---|
| `salt/elasticsearch/auth.sls` | Defines the five named ES service accounts — `so_elastic`, `so_kibana`, `so_logstash`, `so_beats`, `so_monitor` — each pulled from pillar `elasticsearch:auth:users:<name>:pass` with a random fallback |
| `salt/elasticsearch/defaults.yaml` | ES defaults, including the auth block (e.g. `_anonymous` user) |
| `pillar/elasticsearch/{manager,search,nodes,eval}.sls` | Per-node-role ES pillar consumed by `auth.sls` |
| `salt/elasticsearch/ssl.sls` | Generates ES TLS material: `/etc/pki/elasticsearch.key`/`.crt` and a `.p12` keystore |
| `salt/elasticsearch/ca.sls` | Distributes the internal CA + `tls-ca-bundle.pem` so ES/Logstash trust the manager CA |
| `salt/ca/` (`init.sls`, `server.sls`, `signing_policy.sls`, `map.jinja`) | The internal CA authority itself |
| `salt/elasticsearch/files/elasticsearch.yaml.jinja` | Main ES config template wiring cert/key paths into xpack TLS |

This is the pattern our dedicated integration service accounts follow
(least-privilege, per-component — see `migration/integrations/*/README.md`).

## 2. Logstash pipeline definitions

| Path | What it is |
|---|---|
| `salt/logstash/pipelines/config/so/` | The actual pipeline stage configs (`*.conf`/`.jinja`): redis, kafka, elastic_agent, etc. |
| `salt/logstash/pipelines/config/custom/` | Drop-in location for custom pipeline configs |
| `salt/logstash/defaults.yaml` | `assigned_pipelines.roles` (per node role) and `defined_pipelines` (which conf files form each pipeline) |
| `pillar/logstash/{init,nodes}.sls` | Logstash pillar overrides |
| `salt/logstash/config.sls` | State that renders assigned pipelines to `/opt/so/conf/logstash/pipelines/` and `pipelines.yml` |
| `salt/logstash/etc/pipelines.yml.jinja` | Template listing enabled pipelines per node |
| `salt/logstash/map.jinja` | Builds the merged Logstash config map |

## 3. Zeek interface configuration

| Path | What it is |
|---|---|
| `salt/zeek/files/node.cfg.jinja` | `node.cfg` template — sets `interface=af_packet::{{ NODE.interface }}` |
| `salt/zeek/config.map.jinja` | Populates `node.interface` from `ROLE_GLOBALS.sensor.interface` |
| `salt/vars/sensor.map.jinja` | Maps `interface` from pillar `sensor.interface` (pillar source of truth) |
| `pillar/zeek/init.sls` | Zeek pillar defaults/overrides |
| `salt/zeek/config.sls`, `salt/zeek/defaults.yaml` | Zeek state + defaults rendering `node.cfg`/`networks.cfg` |

## 4. Detections module rule-repo mechanism

| Path | What it is |
|---|---|
| `salt/soc/defaults.yaml` (~lines 1380–1650) | Detection-engine config: Sigma/YARA/Suricata engines, `reposFolder` (`/opt/sensoroni/sigma/repos`), and `rulesRepos` referencing `file:///nsm/rules/custom-local-repos/local-sigma` (our deploy target) |
| `salt/soc/config.sls` | Renders `/opt/so/conf/soc/soc.json` and installs detection helper scripts/crons |
| `salt/soc/files/soc/soc.json.jinja` | The templated SOC config consuming those defaults + pillar |
| `salt/soc/files/soc/detections_custom_repo_template_readme.jinja` | README template dropped into `custom-local-repos` for user Sigma rules |
| `salt/soc/merged.map.jinja` | Merges SOC defaults + pillar overrides |

Sigma, YARA, and Suricata all use the same `custom-local-repos` pattern.

## Unlocated items

None — everything above was confirmed present at tag `3.1.0-20260528`.
