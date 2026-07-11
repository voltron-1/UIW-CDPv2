# Security Posture Continuity Audit — Suburban-SOC → UIW-CDPv2

**Date:** 2026-07-10 · **Method:** static repository analysis (no runtime access) · **Framework:** NIST CSF 2.0 (loose alignment)

## 1. Scope & Method

### 1.1 Repositories and commits audited

| Repo | Path | Commit | Branch | Working tree |
|---|---|---|---|---|
| Legacy | `~/projects/Suburban-SOC` | `53ba494fa7baf3d8a32895fb427c08147c433712` | `detections/issue-192-coverage-gaps` | clean |
| Current | `~/projects/UIW-CDPv2` | `4ee4b67d62dd97652d9ae9327a9fd4bc19ed385f` | `docs/planned-exec-refresh` | 3 pre-existing untracked files unrelated to this audit (`CLAUDE.md`, `generate_audit.py`, `repo_audit_packet.md`) |

### 1.2 In-scope directories

**Current repo (`UIW-CDPv2`) — CARDINAL original contributions only:**
`scripts/setup/ai_agent/`, `scripts/hive-mind-broker/`, `scripts/setup/` (provisioning, compose, certs, `isolate.sh`), `rules/sigma/`, `rules/elastic_watcher/`, `detections/`, `configs/`, `migration/`, `governance/`, `.github/workflows/`.

**Excluded:** `reference/` — a gitignored, read-only clone of upstream Security Onion 3.1.0 (confirmed via its nested `.git` remote pointing to `Security-Onion-Solutions/securityonion`). Never cited as a finding target anywhere in this report.

**Legacy repo (`Suburban-SOC`):** entire repository in scope.

### 1.3 Method

Nine parallel audit agents (six dimension audits + two line-level fork-divergence reviews of the shared code lineage + one issue-tracker registry extraction) produced 104 raw findings, each required to cite an absolute file path and line range or explicitly state "not found in repo." Three adversarial verification agents then independently re-read every cited location against the real files (not the audit output) and re-ran every absence probe, treating each citation as wrong until proven otherwise. 93 of 104 findings verified fully clean on first pass; the remainder had only cosmetic issues (loosely-scoped grep probes whose broader match didn't change the underlying conclusion) plus four findings that needed pure language correction — confirmed facts, non-compliant phrasing naming exploit mechanics rather than control state. No finding was rejected or excluded. A synthesis pass deduplicated the 104 raw findings into 66 distinct controls, resolving four verdict conflicts explicitly (§5, §Verdict Conflicts below).

### 1.4 Scoping notes

- Legacy Elasticsearch/Kibana are pinned to **9.3.2**, not 8.x as originally assumed. The `elasticsearch==8.15.1` Python client pin (present in both repos) is a separate, shared client/server version-skew gap — not evidence of an 8.x server.
- The current repo has two copies of the Logstash pipeline config. `docker-compose.yml:73` mounts `scripts/setup/configs/logstash/logstash.conf` — that copy is authoritative at runtime. The root-level `configs/logstash.conf` is an orphaned carryover with functionally identical gaps; both are cited where relevant.
- Issue numbering is **independent per repo** — the same number can mean different things in each (e.g., Legacy `#171` is "broker security events logged via bare `print()`"; UIW `#171` is an unrelated parity-check task). Every tracked-issue reference below is repo-qualified.
- **No genuine improvement or new control was found anywhere in scope.** Two seed hypotheses that the current repo introduced new LLM-safety controls were explicitly disproven during review: the prompt sanitizer pre-exists identically in legacy, and the CISO-report path actually *dropped* a hosted-LLM egress gate legacy had (see §6).
- `hive-mind-broker` has no service definition in current's `scripts/setup/docker-compose.yml` at all (confirmed by direct grep, not inferred). Every broker-side finding in this report describes the control state of forked-but-undeployed source code, not a confirmed-live path — see Open Question #1.

## 2. Executive Summary

**104 raw findings → 66 deduplicated controls.** Zero improvements. Two controls remain equivalent and function as material compensating factors across several regressions: default-autonomy-off (`AUTONOMOUS_ISOLATION`/`AUTONOMOUS_BLOCK_ENABLED` both default false) and LLM-output/containment-trigger isolation (model output never selects or parameterizes a containment action).

| Severity | Count |
|---|---|
| Critical | 2 |
| High | 22 |
| Medium | 19 |
| Low | 7 |
| Equivalent / not applicable | 16 |

### 2.1 Top 5 headline regressions

1. **Unauthenticated privileged endpoints (critical, untracked).** `/approve`, `/pending`, `/weekly-report` on the SOAR agent, and `/approve`/`/pending` on the hive-mind-broker, have no authentication in current; legacy gated all of them behind HMAC. `/approve` executes device/router isolation.
2. **Broker HMAC default secret (critical, untracked).** The broker's signing key falls back to a hardcoded, source-visible value (`default_dev_secret`) with no fail-closed behavior when unset; legacy fails closed (503) with no insecure default.
3. **Sigma/ATT&CK detection coverage collapse (high, partially tracked).** 25 of 35 Sigma rules (71%) and 21 of 31 ATT&CK techniques (68%) present in legacy have no equivalent in current, with zero new techniques added.
4. **CI security gating removed (high×5, untracked).** Secret scanning, container/IaC scanning, dependency auditing, and SOAR/detection merge-gate tests all existed in legacy CI and do not exist in current CI.
5. **Beats ingest transport unprotected (high, untracked).** The endpoint-telemetry input on a host-published port has no TLS or client-certificate authentication in current; legacy required mutual TLS.

### 2.2 Full Summary Table

Legend: ▲ = severity is provisional pending runtime verification (see §8).

#### Secrets & Auth

| Control | Legacy State | Current State | Verdict | Severity | Tracked |
|---|---|---|---|---|---|
| broker-hmac-default-secret | No default; 503 fail-closed if secret unset | Hardcoded `default_dev_secret` fallback; no fail-closed branch | regressed | **critical** | untracked |
| broker-hmac-replay-protection | Timestamp window + single-use nonce cache | Signature over body only; no freshness/nonce gate | regressed | high | untracked |
| agent-hmac-replay-protection | Timestamp window + nonce cache, signs ts+body | Signs body only; no timestamp/nonce gate | regressed | high | untracked |
| agent-hmac-verification | Fail-closed if secret unset, compare_digest | Same base gate preserved | equivalent | — | n/a |
| es-superuser-usage | Least-priv `logstash_internal`/`logstash_writer` role | Authenticates as `elastic` superuser | regressed | high | tracked: UIW #180 |
| es-role-definitions | 7 role JSONs committed + `apply_roles.sh` | No role-definition JSON in scope; documented as open item only | regressed | medium | tracked: UIW #180 |
| es-least-priv-users | `logstash_internal`, `slo_metrics_reader`, `soc_agent_cases` all provisioned | Only Kibana Cases user provisioned; data-plane writers fall back to superuser | regressed | medium | tracked: UIW #180 |
| committed-credential-rotation | No equivalent open item | Origin `#86` credential rotation open; live `.env` gitignored, reset 2026-06-13 (partial compensation) | regressed | ▲high | tracked: UIW #191 |
| cert-lifecycle | 180-day/chmod 600 + `ALLOW_STANDALONE_CERTS` overwrite guard | Same validity/perms; overwrite guard absent | regressed | ▲medium | untracked |
| env-secret-handling | Env-sourced, no hardcoded default | Same posture; broker is the one exception (tracked separately) | equivalent | — | n/a |
| slo-failclosed-measurement | Unmeasurable metric raises `MetricUnavailable`, scored as breach, exit code 3 | Exceptions swallowed, scored as non-breaching n/a — total outage reads as healthy | regressed | medium | untracked |
| es-tls-verify-fallback | `ES_VERIFY` never silently False; errors if CA path missing | `ES_VERIFY` silently False if CA file absent | regressed | medium | untracked |
| slo-metrics-auth-tls | `verify=ES_VERIFY`, CA-checked | Hardcodes `verify=False` on every ES request with basic-auth | regressed | medium | untracked |
| ciso-report-auth-tls | `verify_certs=True`, `ca_certs=ES_CA` | `verify_certs=False` while sending ES API key | regressed | medium | untracked |

#### Detection Coverage

| Control | Legacy State | Current State | Verdict | Severity | Tracked |
|---|---|---|---|---|---|
| sigma-rule-coverage | 35 rule files, Windows + network lanes | 10 rule files, all `proc_creation_win_*`; 25 rules (71%) dropped | regressed | high | tracked: UIW #173 (inventory/classification, not restoration) |
| attack-technique-coverage | 31 distinct ATT&CK technique IDs | 10 IDs, strict subset; 21 legacy techniques (68%) untagged, zero new | regressed | high | tracked: UIW #178; Legacy #8/#26/#27/#28 |
| dac-ci-gates | 4-gate CI: conversion, coverage-matrix, emulation-map, threshold pairing | No detection CI gate; four-gate pipeline is a prose placeholder | regressed | high | tracked: UIW #178 |
| dac-conversion-fidelity | Real pySigma conversion + Kibana Detection Engine import | Self-documented mock conversion; query is a literal tag string, not detection logic | regressed | high | tracked: UIW #175/#102 |
| elastic-threshold-rules | 3 threshold NDJSON rules (bruteforce/spray/cred-sweep) | Directory absent entirely; paired Sigma rules also absent | regressed | high | untracked |
| detection-emulation-validation | `emulation_telemetry.map` + CI-gated validator, ~20 sims | 3 network sims, telemetry-presence check only; no map, no validator, not CI-gated | regressed | medium | tracked: UIW #179 |
| zeek-detection-scripts | `scan-detection.zeek` restores Port_Scan notice (T1046) | Absent from in-scope config; `local.zeek` is telemetry-enrichment only | regressed | medium | untracked |
| watcher-coverage | `intel_feed_stale.json` + `soar_quarantine_alert.json` | `intel_feed_stale.json` absent; detection-health blind spot if intel cron dies | regressed | medium | untracked |
| intel-match-alerting | Static dictionary match + live Zeek Intel-framework match | Static dictionary path only; live feed-driven path absent | regressed | low | untracked |
| rule-quality-signals | ~15/35 real UUIDv4s | 100% placeholder repeating-digit UUIDs; RDP-hijack rule mis-tagged | regressed | low | tracked: UIW #176/#103 (mis-tag); #175 |

#### Automated Response

| Control | Legacy State | Current State | Verdict | Severity | Tracked |
|---|---|---|---|---|---|
| agent/broker-privileged-endpoint-auth | HMAC gate fail-closed on all three endpoints (agent+broker) | No auth on any; `/approve` executes isolation/router block, `/pending` discloses queue | regressed | **critical** | untracked (UIW #94/#181 tracks broker integration generally, not this specific gap) |
| ssh-host-key-verification | Strict by default; opt-out requires explicit `BROKER_INSECURE_SSH` flag | `known_hosts=None` hardcoded, no opt-out flag | regressed | high | untracked |
| exclusion-list-enforcement | Fail-closed at 2 of 3 layers; CIDR/IPv6-aware matching | Fail-open at all 3 layers; exact-string IPv4 match only | regressed | high | untracked |
| NEW-actuator-input-validation | `validate_ip`/`ipaddress` check before dispatch; webhook rejects non-IP | No validation on sink path; only a truthy check on inbound webhook | regressed | high | untracked |
| NEW-broker-tenant-scoping | Dispatch scoped to owning tenant's routers only | No tenant field; every block targets all routers across all tenants | regressed | medium | untracked |
| approval-double-execution-guard | Both agent + broker subtract resolved IDs | Broker guard intact; agent `/approve` no longer subtracts resolved IDs | regressed | medium | untracked |
| response-audit-trail | Agent: append-only ES role asserted. Broker: JSONL with tenant, dispatch-execution, invalid-IP denial lines | Agent facet unchanged. Broker facet drops tenant/dispatch/denial fields, no append-only ES role provisioned | regressed | low | untracked |
| ssh-account-privilege | Defaults to root | Identical | equivalent | — | n/a |
| isolate-script-hostkey | `StrictHostKeyChecking=no`, off automated path | Identical, unchanged | equivalent | — | n/a |
| approval-gate-autonomy-default | `AUTONOMOUS_ISOLATION`/`BLOCK` both default false | Identical defaults, explicit "keep false" comment | equivalent | — | n/a |
| broker-security-event-logging | `print()`/HTTPException only, no persisted record (known gap) | Same shared gap, unchanged | equivalent | — | n/a (shared gap; tracked in legacy's own backlog as Legacy #171, unstarted there too) |
| llm-output-action-isolation | Decision branches only on autonomy flag + severity + valid MAC | Identical isolation preserved | equivalent | — | n/a |

#### Pipeline Integrity

| Control | Legacy State | Current State | Verdict | Severity | Tracked |
|---|---|---|---|---|---|
| beats-logstash-mtls | Server cert + required client cert against stack CA | No transport encryption or client-cert authentication; port host-published | regressed | high | untracked |
| logstash-outbound-alert-signing | HMAC-signed ts+body POST to agent `/alert` | No `/alert` output or HMAC block; only ntfy push remains | regressed | high | untracked |
| watcher-agent-auth-wiring | Signed producer aligned with fail-closed receiver | Two producers misconfigured: one sends no signature, one sends a literal placeholder string | regressed | ▲high | untracked |
| NEW-agent-es-transport | Compose mounts certs volume, sets `ES_CA`/`ES_PASS` | No certs volume mount, no `ES_CA`/`ES_PASS` set in compose | regressed | medium | untracked |
| pipeline-dlq-persistence | `queue.type:persisted` + DLQ enabled, durable volume | No `logstash.yml` in scope; in-memory queue, DLQ disabled by default | regressed | medium | untracked |
| parse-failure-quarantine | Tagged + routed to quarantine index | No parse-failure inspection; single unconditional default index | regressed | medium | untracked |
| pii-stripping-ingest | Removes/redacts auth headers, cookies, credential fields | No field stripping or redaction anywhere in deployed config | regressed | medium | untracked |
| pipeline-tests | `test_grok_parse_failures.py` covers both failure classes | No parse-failure test source; new ingest-lag suite exists for a different purpose | regressed | low | untracked |
| NEW-input-validation-ingest | Anchored grok + timeout + tenant handling | Deployed grok unanchored, no timeout, no tenant handling (agent-side validation unaffected) | regressed | low | untracked |
| es-transport-mtls | `verification_mode=certificate` | Same | equivalent | — | n/a |
| agent-kibana-transport | Plaintext HTTP default | Same plaintext default, shared gap | equivalent | — | n/a |

#### External Exposure

| Control | Legacy State | Current State | Verdict | Severity | Tracked |
|---|---|---|---|---|---|
| port-binding-agent-broker | Agent + broker both loopback-only (127.0.0.1) | Agent published all-interfaces; broker has no compose service/confinement at all | regressed | ▲high | untracked |
| container-user-privilege | Non-root uid 10001 `appuser` | No `USER` directive; runs as default root | regressed | ▲high | untracked |
| NEW-compose-availability-hardening | `mem_limit` on every service; `restart:unless-stopped` on core services | No `mem_limit` anywhere; restart policy only on `ai-agent` | regressed | low | untracked |
| kibana-server-tls | Plaintext HTTP UI listener, no `server.ssl` | Same, shared gap | equivalent | — | n/a |
| broker-dev-server-settings | `reload=True`, mitigated by loopback compose publish | Identical setting, no loopback confinement left to neutralize it | equivalent | — | n/a |
| port-binding-es | All-interfaces, mitigated by xpack.security+TLS+auth | Same | equivalent | — | n/a |
| port-binding-kibana | All-interfaces | Same | equivalent | — | n/a |
| port-binding-logstash | All-interfaces | Same | equivalent | — | n/a |
| docker-network-topology | Single flat bridge, no segmentation | Same, broker simply absent from it | equivalent | — | n/a |

#### Hardening Regressions / CI

| Control | Legacy State | Current State | Verdict | Severity | Tracked |
|---|---|---|---|---|---|
| ci-secret-scanning | Dedicated gitleaks workflow, every push/PR, full history | No secret-scanning workflow exists | regressed | high | untracked |
| ci-image-iac-scanning | Trivy image scan + IaC/compose misconfig scan, exit-1 on CRITICAL | No Trivy scan of any kind | regressed | high | untracked |
| ci-dependency-audit | pip-audit on PR + weekly cron | No pip-audit anywhere | regressed | high | untracked |
| ci-soar-merge-gates | `soar-tests.yml` + `detections.yml` gate every PR | Neither workflow exists | regressed | high | untracked |
| agent-unit-tests | Real `.py` test source wired into CI | No `.py` source; only stale compiled `.pyc` | regressed | high | untracked |
| llm-hosted-egress-gate | Refuses hosted LLM unless `LLM_ALLOW_HOSTED=true` | Gate dropped on CISO-report path; posts metrics to hosted `LLM_API_URL` by default (sibling alert-path gate still present) | regressed | medium | untracked |
| NEW-ci-action-pinning | Every workflow SHA-pinned | `codeql.yml`/`automate-infra-board.yml` use mutable `@v4` tags; `wiki-sync.yml` still SHA-pinned (inconsistent) | regressed | medium | untracked |
| dependency-pinning-broker | Fully pinned incl. CVE-fixed `starlette==1.3.1` floor | Fully unpinned; sibling `ai_agent` requirements remain pinned | regressed | medium | untracked |
| llm-egress-sanitisation | `sanitize_for_llm` + `_is_hosted_endpoint` allowlist | Core sanitiser unchanged; hosted-endpoint allowlist broadened to include `host.docker.internal` | regressed | low | untracked |
| es-client-server-version-skew | Client 8.15.1 vs server 9.3.2 (major skew) | Identical skew, shared pre-existing gap | equivalent | — | n/a |

## 3. Detailed Findings — Citations

Full file:line citations for every regressed control, grouped by dimension and ranked by severity within each. (Equivalent-verdict controls are omitted here for brevity — their states are fully captured in §2.2; underlying citations are preserved in the audit's working files if needed for a follow-up review.)

### 3.1 Secrets & Auth

- **broker-hmac-default-secret** (critical) — `UIW-CDPv2/scripts/hive-mind-broker/app.py:19-20` vs `Suburban-SOC/scripts/hive-mind-broker/app.py:20-22,75-77`
- **broker-hmac-replay-protection** (high) — `UIW-CDPv2/scripts/hive-mind-broker/app.py:57-62` vs `Suburban-SOC/scripts/hive-mind-broker/app.py:23-29,83-106`
- **agent-hmac-replay-protection** (high) — `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:98-119` vs `Suburban-SOC/scripts/setup/ai_agent/agent_app.py:112-118,129-177`
- **es-superuser-usage** (high) — `UIW-CDPv2/scripts/setup/configs/logstash/logstash.conf:115-130` vs `Suburban-SOC/configs/logstash.conf:474-496`
- **committed-credential-rotation** (▲high) — `UIW-CDPv2/planned_execution.md:117`, `UIW-CDPv2/scripts/setup/.env:1-9`
- **es-role-definitions** (medium) — `UIW-CDPv2/planned_execution.md:99` vs `Suburban-SOC/configs/elasticsearch/roles/soc_audit_appender.json:1-5`
- **es-least-priv-users** (medium) — `UIW-CDPv2/scripts/setup/provision_soc_agent.sh:5-8,43` vs `Suburban-SOC/scripts/setup/apply_roles.sh:3-8`
- **cert-lifecycle** (▲medium) — `UIW-CDPv2/scripts/setup/generate_certs.sh:19-24,57` vs `Suburban-SOC/scripts/setup/generate_certs.sh:31-42,47,80`
- **slo-failclosed-measurement** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/slo_metrics.py:72-77,115-117,178-179` vs `Suburban-SOC/scripts/setup/ai_agent/slo_metrics.py:63-68,83-87,217-221`
- **es-tls-verify-fallback** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:54-56` vs `Suburban-SOC/scripts/setup/ai_agent/agent_app.py:54-60`
- **slo-metrics-auth-tls** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/slo_metrics.py:60-64` vs `Suburban-SOC/scripts/setup/ai_agent/slo_metrics.py:71-76,90-94`
- **ciso-report-auth-tls** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/weekly_ciso_report.py:91` vs `Suburban-SOC/scripts/setup/ai_agent/weekly_ciso_report.py:31-34,98-100`

### 3.2 Detection Coverage

- **sigma-rule-coverage** (high) — `UIW-CDPv2/rules/sigma/` (10 files) vs `Suburban-SOC/rules/sigma/` (35 files), independently recounted twice
- **attack-technique-coverage** (high) — same directories; legacy 31 distinct technique IDs vs current 10 (strict subset, 21 dropped: T1003.002, T1018, T1021, T1027, T1046, T1055, T1078, T1087.002, T1098, T1110, T1110.003, T1134, T1140, T1218.005, T1490, T1543.003, T1546.003, T1547.001, T1562.001, T1562.002, T1569.002)
- **dac-ci-gates** (high) — `UIW-CDPv2/migration/ci/README.md:1-4` vs `Suburban-SOC/.github/workflows/detections.yml:36-61`
- **dac-conversion-fidelity** (high) — `UIW-CDPv2/scripts/setup/translate_rules.py:31-46`, `UIW-CDPv2/rules/elastic_watcher/proc_creation_win_local_acct_create.ndjson:1`
- **elastic-threshold-rules** (high) — `UIW-CDPv2/rules/elastic/` (absent) vs `Suburban-SOC/rules/elastic/threshold/` (3 files)
- **detection-emulation-validation** (medium) — `UIW-CDPv2/tests/anomaly_simulation/verify_detections.py:31-45` vs `Suburban-SOC/tests/validate_emulation_map.py:5-14`
- **zeek-detection-scripts** (medium) — `UIW-CDPv2/configs/zeek/local.zeek:8-9` vs `Suburban-SOC/scripts/setup/configs/zeek/scan-detection.zeek:17-78`
- **watcher-coverage** (medium) — `UIW-CDPv2/rules/elastic_watcher/hive_mind_bruteforce.json:14-16,44-50` vs `Suburban-SOC/rules/elastic_watcher/intel_feed_stale.json:3-6,42-48`
- **intel-match-alerting** (low) — `UIW-CDPv2/configs/logstash.conf:99-115,137-149` vs `Suburban-SOC/configs/logstash.conf:140-160`
- **rule-quality-signals** (low) — `UIW-CDPv2/rules/sigma/` (placeholder UUIDs), `UIW-CDPv2/planned_execution.md:89`

### 3.3 Automated Response

- **agent/broker-privileged-endpoint-auth** (critical) — `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:730-757`, `UIW-CDPv2/scripts/hive-mind-broker/app.py:106-138` vs `Suburban-SOC/scripts/setup/ai_agent/agent_app.py:180-196`
- **ssh-host-key-verification** (high) — `UIW-CDPv2/scripts/hive-mind-broker/dispatcher.py:51-56` vs `Suburban-SOC/scripts/hive-mind-broker/dispatcher.py:34-47,138`
- **exclusion-list-enforcement** (high) — `UIW-CDPv2/scripts/hive-mind-broker/dispatcher.py:18-26,29-30`, `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:217-248`
- **NEW-actuator-input-validation** (high) — `UIW-CDPv2/scripts/hive-mind-broker/dispatcher.py:36-37`, `UIW-CDPv2/scripts/hive-mind-broker/app.py:73-75` vs `Suburban-SOC/scripts/hive-mind-broker/dispatcher.py:118-120`
- **NEW-broker-tenant-scoping** (medium) — `UIW-CDPv2/scripts/hive-mind-broker/inventory.yaml:6-15`, `UIW-CDPv2/scripts/hive-mind-broker/app.py:83,137`
- **approval-double-execution-guard** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:749-752` vs `Suburban-SOC/scripts/setup/ai_agent/agent_app.py:875-882`
- **response-audit-trail** (low) — `UIW-CDPv2/scripts/hive-mind-broker/app.py:139-140` vs `Suburban-SOC/scripts/hive-mind-broker/app.py:215-219`, `Suburban-SOC/scripts/setup/docker-compose.yml:155-156`

### 3.4 Pipeline Integrity

- **beats-logstash-mtls** (high) — `UIW-CDPv2/scripts/setup/configs/logstash/logstash.conf:3-6`, `UIW-CDPv2/scripts/setup/docker-compose.yml:65-66` vs `Suburban-SOC/configs/logstash.conf:6-13`
- **logstash-outbound-alert-signing** (high) — `UIW-CDPv2/scripts/setup/configs/logstash/logstash.conf:114-146` vs `Suburban-SOC/configs/logstash.conf:428-447,521-536`
- **watcher-agent-auth-wiring** (▲high) — `UIW-CDPv2/rules/elastic_watcher/soar_quarantine_alert.json:86-99`, `UIW-CDPv2/rules/elastic_watcher/hive_mind_bruteforce.json:38-52`
- **NEW-agent-es-transport** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:53-56` vs `Suburban-SOC/scripts/setup/docker-compose.yml:413-416`
- **pipeline-dlq-persistence** (medium) — `UIW-CDPv2/scripts/setup/docker-compose.yml:72-80` vs `Suburban-SOC/configs/logstash.yml:19-29`
- **parse-failure-quarantine** (medium) — `UIW-CDPv2/scripts/setup/configs/logstash/logstash.conf:114-130` vs `Suburban-SOC/configs/logstash.conf:342-347,463-473`
- **pii-stripping-ingest** (medium) — `UIW-CDPv2/scripts/setup/configs/logstash/logstash.conf:79-112` vs `Suburban-SOC/configs/logstash.conf:354-378`
- **pipeline-tests** (low) — `UIW-CDPv2/migration/parity/test_ingest_lag.py:83-95` vs `Suburban-SOC/tests/pipeline/test_grok_parse_failures.py:14-19`
- **NEW-input-validation-ingest** (low) — `UIW-CDPv2/scripts/setup/configs/logstash/logstash.conf:72-75` vs `Suburban-SOC/configs/logstash.conf:283-304`

### 3.5 External Exposure

*(Every finding in this dimension is marked ▲ needs_runtime_verification — deployed host firewall rules and actual network topology cannot be confirmed statically.)*

- **port-binding-agent-broker** (▲high) — `UIW-CDPv2/scripts/setup/docker-compose.yml:81-86` vs `Suburban-SOC/scripts/setup/docker-compose.yml:443-446,488-490`
- **container-user-privilege** (▲high) — `UIW-CDPv2/scripts/setup/ai_agent/Dockerfile:25-32` vs `Suburban-SOC/scripts/setup/ai_agent/Dockerfile:28-33`
- **NEW-compose-availability-hardening** (low) — `UIW-CDPv2/scripts/setup/docker-compose.yml:107` vs `Suburban-SOC/scripts/setup/docker-compose.yml:177-178`

### 3.6 Hardening Regressions / CI

- **ci-secret-scanning** (high) — `UIW-CDPv2/.github/workflows/` (3 files, no `secret-scan.yml`) vs `Suburban-SOC/.github/workflows/secret-scan.yml:1-22`
- **ci-image-iac-scanning** (high) — `UIW-CDPv2/.github/workflows/` (no `security-scan.yml`) vs `Suburban-SOC/.github/workflows/security-scan.yml:36-71`
- **ci-dependency-audit** (high) — `UIW-CDPv2/.github/workflows/` (no pip-audit step) vs `Suburban-SOC/.github/workflows/security-scan.yml:19-34`
- **ci-soar-merge-gates** (high) — `UIW-CDPv2/.github/workflows/` (no `soar-tests.yml`/`detections.yml`) vs `Suburban-SOC/.github/workflows/soar-tests.yml:17-49`
- **agent-unit-tests** (high) — `UIW-CDPv2/tests/unit/__pycache__/test_agent_app.cpython-312.pyc` vs `Suburban-SOC/tests/ai_agent/test_alert_auth.py:1`
- **llm-hosted-egress-gate** (medium) — `UIW-CDPv2/scripts/setup/ai_agent/weekly_ciso_report.py:151-187` vs `Suburban-SOC/scripts/setup/ai_agent/weekly_ciso_report.py:40,165-172`
- **NEW-ci-action-pinning** (medium) — `UIW-CDPv2/.github/workflows/codeql.yml:58,68,97` vs `Suburban-SOC/.github/workflows/codeql.yml:58,68,97`
- **dependency-pinning-broker** (medium) — `UIW-CDPv2/scripts/hive-mind-broker/requirements.txt:1-6` vs `Suburban-SOC/scripts/hive-mind-broker/requirements.txt:4-11`
- **llm-egress-sanitisation** (low) — `UIW-CDPv2/scripts/setup/ai_agent/agent_app.py:259-276` vs `Suburban-SOC/scripts/setup/ai_agent/agent_app.py:376-390`

## 4. Lineage Divergence Review

The two repos share direct code lineage — `agent_app.py`, the hive-mind-broker (`app.py`/`dispatcher.py`), `isolate.sh`, `governance/exclusion_list.txt`, `docker-compose.yml`, `generate_certs.sh`, `slo_metrics.py`, and `weekly_ciso_report.py` all exist in both at parallel paths. Legacy underwent a documented "Structural Health Review Remediation" (Priority 1 complete, Priority 2 in progress) that current's forked copies did not receive. Two dedicated line-level fork-divergence agents compared every pair directly; nearly every divergence found was a regression relative to legacy, corroborating the independent dimension-based findings above (see the merge annotations in §2.2 — most controls were found independently by both a dimension agent and a lineage agent, which is itself a strong reliability signal).

Forked pairs reviewed: `agent_app.py`, `slo_metrics.py`, `weekly_ciso_report.py`, `elastic_watcher/*.json` wiring, `logstash.conf` (all copies in both repos), `hive-mind-broker/app.py`, `dispatcher.py`, `inventory.yaml`, `isolate.sh`, `exclusion_list.txt`, `docker-compose.yml`, `generate_certs.sh`.

## 5. Prioritized Regressions & Gaps

Ranked by severity tier, then exposure (external/host-published before internal-only), then untracked before tracked within the same tier. Impact stated only — no exploit mechanics or attack sequences.

### Critical

1. **agent/broker-privileged-endpoint-auth** — Authentication is fully absent on the SOAR endpoints that execute device/router isolation and disclose the pending-action queue. Blast radius: unauthorized containment action and queue disclosure across the whole response pipeline. *Untracked.*
2. **broker-hmac-default-secret** — Signing-key control degrades to a hardcoded, source-published value when the environment secret is unset, with no fail-closed branch. Blast radius: unauthorized containment dispatch to routers across every tenant. *Untracked.*

### High (22, abbreviated to top 10; full list in §2.2)

3. port-binding-agent-broker — management-plane services lost loopback confinement
4. beats-logstash-mtls — endpoint/network telemetry ingest has no transport encryption or authentication
5. agent-hmac-replay-protection — freshness/nonce controls absent on the now LAN-reachable isolation-trigger endpoint
6. container-user-privilege — the now LAN-published webhook listener's container runs as root
7. logstash-outbound-alert-signing — the pipeline's signed alert-to-SOAR delivery path is gone
8. watcher-agent-auth-wiring — both current alert-trigger sources are misconfigured against fail-closed receivers
9. broker-hmac-replay-protection — no freshness/nonce gate on signed broker requests
10. ssh-host-key-verification — host-key verification disabled by default on the root remote-administration channel to routers
11. exclusion-list-enforcement — the never-block allowlist protecting core infrastructure regressed from fail-closed to fail-open
12. NEW-actuator-input-validation — no input validation before a root-executed command-construction path

*(Remaining 12 high-severity items: elastic-threshold-rules, ci-secret-scanning, ci-image-iac-scanning, ci-dependency-audit, ci-soar-merge-gates, agent-unit-tests, es-superuser-usage, committed-credential-rotation, dac-ci-gates, sigma-rule-coverage, attack-technique-coverage, dac-conversion-fidelity — see §2.2/§3 for full detail.)*

### Medium (19) and Low (7)

See §2.2 for the complete table; full citations in §3.

## 6. Improvements & New Controls

**None found.** Two seed hypotheses from initial exploration were explicitly disproven during this audit:

- **LLM prompt-injection hardening and egress sanitiser were hypothesized as new controls in current.** Verified false: `sanitize_for_llm`, `_is_hosted_endpoint`, and the injection-resistant system prompt all pre-exist identically in legacy (`Suburban-SOC/scripts/setup/ai_agent/agent_app.py:376-419`). The only delta is a marginal *broadening* of the hosted-endpoint allowlist in current (low-severity sub-regression, see llm-egress-sanitisation).
- **The CISO-report hosted-LLM egress gate was hypothesized as present.** Verified false: current's `weekly_ciso_report.py` *dropped* the `LLM_ALLOW_HOSTED` policy check that legacy enforces, so aggregate SOC posture metrics now egress to a third-party hosted LLM by default (medium severity, llm-hosted-egress-gate).

Two controls remain **equivalent** and are worth naming as compensating factors that limit the practical impact of several regressions above: default-autonomy-off (`approval-gate-autonomy-default`) and LLM-output/containment-trigger isolation (`llm-output-action-isolation`).

## 7. Not Assessable Statically

- **CARDINAL-authored Salt states, pillars, or firewall/so-allow overrides** — none exist in the repository; all Salt/firewall references in current point only into `reference/` (out of scope). This sub-dimension of "external exposure" is not applicable to CARDINAL's original contribution.
- Git-tracked/history status of `.env` and certificate private keys (`ca.key`, `es.key`) in the current repository — no git-history tooling was available to the auditing agents; inferred only from `.gitignore` coverage and the open rotation-tracking item.
- Runtime validity of the historically-committed `elastic` superuser credential — requires live ES authentication plus git-history inspection.
- Whether Security Onion-native detections (`reference/`, explicitly out of scope) offset the 21 dropped ATT&CK techniques, 3 dropped threshold rules, or the dropped Zeek port-scan notice.
- Whether the current Logstash CRITICAL_THREAT/ntfy path and the hive-mind-broker webhook alert paths fire end-to-end.
- Whether the append-only `soc_audit_appender` ES role is actually provisioned/granted on a running current-repo cluster, or exists only as a code-comment assertion.
- Runtime docker-compose `user:` overrides for the `ai_agent` service (a possible compensating control for container-user-privilege).
- Whether `elasticsearch-py` 8.15.1 functions correctly against a 9.3.2 ES cluster at runtime.
- Whether legacy Suburban-SOC actually mounts the root-level `configs/logstash.conf` or the `scripts/setup/` copy at runtime (the equivalent question was resolved for current; not confirmed for legacy).
- Whether broker-side deploy tooling substitutes a real HMAC value for the literal placeholder `KIBANA_HMAC_SIGNATURE` in `hive_mind_bruteforce.json`.

## 8. Open Questions — Runtime Verification Required on cardinal-so

1. Is `hive-mind-broker` deployed on cardinal-so by any mechanism outside the audited `docker-compose.yml` — this directly determines whether the CRITICAL broker-auth cluster is a live control gap or a dormant one in forked-but-undeployed source.
2. Do the actual deployed port bindings on cardinal-so match the `docker-compose.yml` declarations audited here (agent `:5000`, ES `:9200`, Kibana `:5601`, Logstash `:5044`)?
3. Was the historically-committed elastic superuser credential (origin UIW #86, rotation tracked at UIW #191) actually rotated, and does the pre-rotation value remain valid or reachable in git history?
4. Do Security Onion-native detections offset any of the 21 dropped MITRE ATT&CK techniques or the 3 dropped Elastic threshold rules?
5. Does the `elasticsearch-py` 8.15.1 client function correctly against the deployed ES 9.3.2 server at runtime (version-skew compatibility), shared by both repos?
6. Is the legacy Suburban-SOC stack still running, which is relevant to the parity-check work item UIW #171?
7. Were any historically-generated private key files (e.g., `scripts/setup/certs/ca/ca.key`, `es/es.key`) ever committed to the current repository's git history?
8. Do the current Logstash CRITICAL_THREAT/ntfy path and the hive-mind-broker webhook alert path actually fire end-to-end at runtime as configured?
9. Does the broker enforce signature/timestamp verification against the placeholder `KIBANA_HMAC_SIGNATURE` value in `hive_mind_bruteforce.json`, or does deploy tooling substitute a real signature at deploy time?
10. What is the effective runtime UID of the `ai_agent` container (via compose `user:` override or userns-remap), which could compensate for the missing Dockerfile `USER` directive?
11. Does legacy Suburban-SOC actually mount the root-level `configs/logstash.conf` or the `scripts/setup/configs/logstash/logstash.conf` copy at runtime, mirroring the same authoritative-copy question resolved for current?
12. Is the `soc_audit_appender` append-only ES role actually provisioned/granted on the running current-repo cluster, or does it exist only as a code-comment assertion?

### 8.1 Answers Provided (2026-07-11)

| # | Question | Answer | Implication |
|---|---|---|---|
| 1 | Broker deployed outside audited compose? | Not believed to be | Softens (but does not eliminate) the likelihood that the two CRITICAL broker-auth findings are an active live-reachable gap today. Control **state** remains critical and must still be fixed before UIW #94/#181 ships the broker. |
| 2 | Deployed port bindings match compose? | Unknown | Still open. |
| 3 | Historically-committed elastic credential rotated? | **Yes, rotated** | `committed-credential-rotation` (UIW #191): rotation itself is confirmed complete. Whether the pre-rotation value was scrubbed from git history remains unconfirmed (see Q7) — recommend keeping #191 open until that's verified, since a stale-but-valid-looking credential can still be found by anyone who clones the repo history. |
| 4 | SO-native detections offset dropped ATT&CK techniques? | Not sure | Still open — do **not** treat any detection-coverage finding as mitigated on this basis. |
| 5 | ES client (8.15.1) works against server (9.3.2)? | Believed yes | Resolves the open question with low-confidence confirmation; `es-client-server-version-skew` was already rated equivalent (shared gap), no severity change. |
| 6 | Is legacy Suburban-SOC still running? | **No** | Two consequences: (a) the parity-check work item (UIW #171) cannot be validated against a live legacy system as currently scoped — will need pcap replay or historical data instead of a running comparison target; (b) legacy no longer functions as an operational safety net. Current is now the **only live system**, which raises the practical urgency of the untracked regressions in this report (they're no longer "current vs. a system still running in parallel" — they're current's actual, sole, live posture). |
| 7 | Cert/key material or credentials committed to git history? | Not sure | Still open — directly relevant to closing #191 (see Q3). |
| 8 | Do the alert-delivery paths fire end-to-end? | User offered to start the pipeline for live testing | Not yet done — see follow-up below. |
| 9 | Broker substitutes a real signature for the placeholder? | Unknown | Still open. |
| 10 | Effective runtime UID of the ai_agent container? | Unknown | Still open. |
| 11 | Does legacy mount the root-level or `scripts/setup/` copy of `logstash.conf`? | Unknown | Still open — does not affect current-repo findings either way. |
| 12 | Is `soc_audit_appender` actually granted at runtime? | Unknown | Still open. |

**Note on Q8:** starting the pipeline to observe live alert delivery is a state-changing action (spins up the Docker Compose stack) and a new task beyond this audit's static-analysis scope — see the follow-up question at the end of this session's conversation for how to proceed.

## 9. NIST CSF 2.0 Category Rollup

| Category | Improved | Equivalent | Regressed |
|---|---|---|---|
| Identify | 0 | 1 | 3 |
| Protect | 0 | 12 | 24 |
| Detect | 0 | 1 | 11 |
| Respond | 0 | 2 | 4 |
| Govern | 0 | 0 | 8 |
| **Total** | **0** | **16** | **50** |

## Appendix A: Verdict Conflicts Resolved

Four merge-time conflicts were resolved explicitly during synthesis, favoring the worse verdict/higher severity per the audit's stated dedup rule:

1. **Severity-discount pattern (broker-hmac-default-secret, agent/broker-privileged-endpoint-auth, ssh-host-key-verification).** Some source agents discounted the broker-auth cluster from critical to high, reasoning "the broker has no service definition in current's docker-compose.yml." Resolved to **critical** for the two HMAC/auth-absence clusters — control *state* is critical regardless of current wiring; deployment status is a runtime/mitigating factor, not a state downgrade, and is preserved as Open Question #1 instead. `ssh-host-key-verification` itself was kept at **high** since it is a narrower, single-facet control whose own reasoning stands independently.
2. **cert-lifecycle.** One source finding rated the missing `ALLOW_STANDALONE_CERTS` overwrite guard as equivalent (availability-only, not a hardening regression); another rated it regressed/medium (a real availability blast radius — accidental CA/cert overwrite can break TLS and halt ingestion). Resolved to **regressed/medium**.
3. **response-audit-trail.** Agent-side facet is equivalent; broker-side facet is regressed (dropped tenant/dispatch/denial fields, no append-only ES role provisioned). Resolved to **regressed/low** for the merged control, with the agent-side equivalence noted separately.
4. **container-user-privilege.** Rated medium by one source, high by another describing the identical fact (missing Dockerfile `USER` directive). Resolved to **high**, reflecting that the affected container is also the one found to be newly LAN-published (port-binding-agent-broker).

## Appendix B: Unverified Observations

None. All 104 raw findings were either confirmed clean by adversarial citation verification or had only cosmetic/non-substantive issues (loosely-scoped absence probes whose broader match didn't change the underlying conclusion, or pure language corrections for framing compliance). No finding was excluded from this report.

## Appendix C: Severity Rubric & Framing Rules Used

**Severity (impact/blast-radius only, never exploit mechanics or attacker step-count):**
- **Critical** — control fully absent or fail-open by default on a privileged/destructive control plane, or credential exposure granting control-plane access.
- **High** — control absent or degraded on an externally-exposed service, or on an authentication path where the control partially remains.
- **Medium** — control degraded with compensations or internal-only reach.
- **Low** — defense-in-depth/hygiene deltas.
- **▲** modifier — severity is provisional pending runtime verification (host firewall rules, actual deployment topology, etc. cannot be confirmed statically).

**Framing:** every finding in this report describes control *state* — present, absent, degraded, fail-open, fail-closed, coverage gap, hardening regression — never exploit mechanics, bypass walkthroughs, or attacker step sequences. Four findings required wording correction after adversarial verification confirmed their underlying facts but flagged non-compliant phrasing (e.g., "an unauthenticated caller can list drafted actions, approve, and execute" was rewritten to "no authentication on /pending, /approve"); the corrected wording is what appears throughout this report.

## Appendix D: Follow-up Investigation (2026-07-11)

### D.1 Answers to Open Questions §8 — Follow-up Findings

Runtime-verification answers were collected from the repository owner on 2026-07-11 (§8.1 above). Three of the answered questions warranted further static investigation; results:

- **Q7 (secrets in git history) — CONFIRMED PRESENT.** The commit that claims to "scrub" the committed `elastic` credential (`f3a1454`, 2026-06-13) is itself explicit that the scrub was incomplete: *"NOTE: history still contains the secret — rotate the live password and run git filter-repo/BFG (owner action)."* Direct inspection of the pre-scrub diff confirms the plaintext value is fully recoverable from prior commits in the branch that contains this fix (`chore/audit-remediation` — see D.2). It was never present in the audited branch's own history (`docs/planned-exec-refresh`). Net: the exposure is real and reachable within the repository, but confined to one branch's history rather than the branch this audit evaluated. Combined with the user's confirmation (Q3) that the live password has been rotated, the residual risk is the historical string itself remaining permanently recoverable by anyone with repository access — not a currently-valid credential. `committed-credential-rotation` should stay open specifically for the `git filter-repo`/BFG history rewrite, not the rotation itself.
- **Q11 (which `logstash.conf` does legacy mount) — RESOLVED.** Legacy mounts the root-level `configs/logstash.conf` directly (`Suburban-SOC/scripts/setup/docker-compose.yml:387`, comment: *"Single source of truth: the repo-root pipeline config is mounted directly... No copy/sync step"*) and never had a second copy under `scripts/setup/configs/logstash/` — that path does not exist in legacy. The duplicate-copy structure present in the current repo was introduced during the fork itself, not inherited.
- **Q12 (`soc_audit_appender` role grant) — CONFIRMED ABSENT from any repo-tracked mechanism.** A repo-wide search for `soc_audit_appender` and any `_security/role` provisioning call in the current repo's scope found only a code comment in `agent_app.py:562` asserting the role and an unrelated future-work note; no role JSON, no `apply_roles`-equivalent script, and no API call provisioning this role exists anywhere in tracked code. If granted at all, it was done manually and out-of-band, invisible to version control.
- **Q2, Q9, Q10 remain open** — each requires access to the live deployed host or a running pipeline, which was not pursued per the owner's direction to avoid starting the stack.
- **Q4 (Security Onion-native detection offset) — INVESTIGATED, partial/narrow offset at most.** `reference/` contains only Security Onion's Salt/pillar configuration — rule *bodies* (Suricata, Sigma, YARA) are fetched from external sources at install/runtime and are not vendored in this checkout, capping how precisely coverage can be confirmed. What is confirmable: Suricata's default ruleset (ET Open) provides broad network-layer signature coverage but has little to say about host-centric techniques (credential dumping, process injection, token manipulation, WMI persistence, disabling security tooling). Sigma rule auto-enablement (via SO's Elastalert integration) is severity- and category-gated — only `critical` (or `critical`/`high` for SO's own resource pack) severity rules in a specific narrow set of logsource categories are enabled by default (`salt/soc/defaults.yaml:1391-1420`); several of the 21 dropped techniques fall outside that allow-list by category (confirmed gap: T1546.003/WMI event subscription) or would need an upstream rule at exactly the right severity (unconfirmable without vendored rule content). Zeek ships a native SSH brute-force detection by default (`salt/zeek/defaults.yaml:48`), partially covering one of the three dropped threshold behaviors; there is no native equivalent for password-spraying or explicit-credential account-sweep, and no default network-scan detection (T1046 gap confirmed — no scan script in Zeek's default load list). **Net: Security Onion's native content does not substantially close the 21-technique / 3-threshold-rule gap identified in §2/§3; it offers plausible partial coverage for a subset of techniques contingent on upstream rule content this repository does not contain, plus confirmed gaps for network scanning, WMI persistence, and two of the three threshold behaviors.**

### D.2 Comparison Against Unmerged Branch `chore/audit-remediation`

While investigating Q7, a second local branch was discovered: `chore/audit-remediation`, which shares a common ancestor with the audited branch (`docs/planned-exec-refresh`) but has **never been merged into it** (`git merge-base --is-ancestor` confirms it is not an ancestor of `HEAD`). It touches 33 files (806 insertions) and includes the credential-scrub commit referenced in D.1, plus substantial changes to the Logstash pipeline, Sigma rules, CI configuration, and the SOAR agent's reporting scripts. All 24 currently-open findings from §5 were checked against this branch to determine whether any are already resolved there. Method: read-only `git diff`/`git show` against `chore/audit-remediation`, no checkout or merge performed.

**Result: both CRITICAL findings remain fully open on this branch.** `scripts/hive-mind-broker/` (the entire broker — `app.py`, `dispatcher.py`, `inventory.yaml`) is absent from the branch's changed-file list in its entirety — it was never touched. `scripts/setup/ai_agent/agent_app.py` (the SOAR agent's core auth/approval logic) was likewise never touched; this was independently confirmed by directly reading the file's content **as it exists on `chore/audit-remediation`**, which still shows no authentication on `/approve`, `/pending`, or `/weekly-report`, and no replay-protection logic anywhere in the file.

Of the 22 High/Medium/Low findings checked:

| Verdict | Count | Findings |
|---|---|---|
| ✅ Resolved | 5 | `slo-metrics-auth-tls`, `ciso-report-auth-tls`, `llm-hosted-egress-gate`, `rule-quality-signals` (mis-tag sub-claim only), `.dockerignore` secrets hygiene (not a formal finding) |
| ⚠️ Partially resolved | 3 | `dac-ci-gates` (Sigma field/tag completeness gate only — no conversion check, no coverage-matrix sync, no emulation-map validation), `agent-unit-tests` (real test source now exists and runs in CI, but covers only HMAC-verify and IP/MAC validators — not auth/approval/exclusion logic — and the CI job is non-blocking), `NEW-compose-availability-hardening` (restart policies added to all core services; `mem_limit` still absent everywhere) |
| ⭐ New improvement beyond parity | 1 | `isolate-script-hostkey` — `StrictHostKeyChecking` changed from `no` to `accept-new`, a control neither repo previously had |
| ❌ Not resolved | 22 | see full breakdown below |

**Not resolved (grouped by root cause):**

- **Pipeline Integrity — 0 of 7 resolved.** The branch's Logstash changes (156/152 lines across both `logstash.conf` copies, which remain duplicated) are scoped entirely to ECS field-mapping and routing-bug fixes. `pii-stripping-ingest`, `parse-failure-quarantine`, `pipeline-dlq-persistence`, `logstash-outbound-alert-signing`, `es-superuser-usage`, `beats-logstash-mtls`, and `NEW-input-validation-ingest` are all untouched. A new Winlogbeat producer was even added onto the same unencrypted Beats port.
- **CI/CD security gates — 0 of 4 high-severity gaps resolved.** `ci-secret-scanning`, `ci-image-iac-scanning`, `ci-dependency-audit` have no equivalent in the new `ci.yml`; `ci-soar-merge-gates` remains unresolved because the one job that runs tests is explicitly non-blocking (`continue-on-error: true`, `pytest ... || true`) and doesn't test the security-critical logic. `NEW-ci-action-pinning` is also unresolved — the new workflow uses the same mutable action tags.
- **Detection conversion fidelity — not resolved.** The 137-line rewrite of `translate_rules.py` fixed adjacent bugs (risk-score ordering, index naming, path handling) but its own new module docstring explicitly states the query-generation logic is still a placeholder and defers the real fix to a separate open issue (#110); confirmed directly by reading the regenerated `.ndjson` output — query fields are unchanged, still literal tag strings rather than translated detection logic.
- **Detection coverage restoration — not resolved.** No `.yml` files were added to `rules/sigma/`; the branch modifies only the one file needed for the mis-tag fix. Rule count remains 10 vs. legacy's 35.
- **Broker/agent auth cluster — entirely untouched**, as stated above (both criticals, plus `broker-hmac-replay-protection`, `agent-hmac-replay-protection`, `ssh-host-key-verification` (broker side), `exclusion-list-enforcement`, `NEW-actuator-input-validation`, `NEW-broker-tenant-scoping`, `approval-double-execution-guard`, `response-audit-trail`).
- **Least-privilege ES accounts — not resolved.** A new `provision_kibana_system.sh` was added, but it only sets the password on Elasticsearch's *built-in* `kibana_system` service account (fixing a narrower, unrelated bootstrap issue) — it creates no least-privilege role for Logstash or `slo_metrics`, both of which still explicitly log a warning in their own code that they are running as the superuser.
- **Everything else untouched:** `elastic-threshold-rules`, `watcher-agent-auth-wiring`, `watcher-coverage`, `zeek-detection-scripts`, `detection-emulation-validation`, `container-user-privilege`, `port-binding-agent-broker`, `NEW-agent-es-transport`, `cert-lifecycle`, `es-tls-verify-fallback`, `slo-failclosed-measurement`, `dependency-pinning-broker`.

**Practical implication:** despite its size, `chore/audit-remediation` does not represent a comprehensive remediation of this audit's findings. It resolves a handful of medium/low-severity items concentrated in the SOAR agent's reporting scripts, plus one detection-metadata correction, while leaving every high-severity CI gate, the entire broker subsystem, both critical findings, and all pipeline-hardening gaps completely open. Merging it would be a net improvement with no observed regressions, but should not be treated as closing more than the specific items listed above as "Resolved" or "Partially resolved."
