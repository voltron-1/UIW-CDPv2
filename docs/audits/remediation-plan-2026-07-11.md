# Remediation Plan — Security Posture Continuity Findings

**Date:** 2026-07-11 · **Source:** `docs/audits/security-posture-diff-2026-07-10.md` (§5, §Appendix D) · **Status:** planning only — no code changed by this document

## How to read this plan

47 findings remain open after cross-checking against the unmerged `chore/audit-remediation` branch (2 critical, 22 high, 16 medium, 7 low). They're grouped into 8 workstreams by shared root cause/file, since most of these get fixed together in practice, not one at a time. Workstreams are ordered by the highest severity finding they contain. Within each workstream, items are listed most-severe-first. If you want a flat, no-grouping priority order instead, use the **Quick Priority Index** below — it's the same 47 items, same order, just without the workstream framing.

**Sequencing note:** Workstream A (broker/agent auth) should go first regardless of team capacity — it's the only workstream containing both critical findings, and several other workstreams (C: CI gates, in particular `ci-soar-merge-gates`) can't meaningfully close until A's fixes land, because there's nothing correct to test yet.

## Quick Priority Index

1. `agent/broker-privileged-endpoint-auth` — **critical**
2. `broker-hmac-default-secret` — **critical**
3. `broker-hmac-replay-protection` — high
4. `agent-hmac-replay-protection` — high
5. `es-superuser-usage` — high (tracked UIW #180)
6. `committed-credential-rotation` — high (tracked UIW #191, scope narrowed to history-scrub only)
7. `port-binding-agent-broker` — high
8. `beats-logstash-mtls` — high
9. `watcher-agent-auth-wiring` — high
10. `logstash-outbound-alert-signing` — high
11. `ssh-host-key-verification` — high
12. `exclusion-list-enforcement` — high
13. `NEW-actuator-input-validation` — high
14. `elastic-threshold-rules` — high
15. `ci-secret-scanning` — high
16. `ci-image-iac-scanning` — high
17. `ci-dependency-audit` — high
18. `ci-soar-merge-gates` — high
19. `agent-unit-tests` — high (partial progress exists)
20. `sigma-rule-coverage` — high (tracked UIW #173)
21. `attack-technique-coverage` — high (tracked UIW #178)
22. `dac-ci-gates` — high (partial progress exists, tracked UIW #178)
23. `dac-conversion-fidelity` — high (tracked UIW #175/#102)
24. `container-user-privilege` — high
25. `es-role-definitions` — medium (tracked UIW #180)
26. `es-least-priv-users` — medium (tracked UIW #180)
27. `cert-lifecycle` — medium
28. `slo-failclosed-measurement` — medium
29. `es-tls-verify-fallback` — medium
30. `NEW-agent-es-transport` — medium
31. `pipeline-dlq-persistence` — medium
32. `parse-failure-quarantine` — medium
33. `pii-stripping-ingest` — medium
34. `NEW-broker-tenant-scoping` — medium
35. `approval-double-execution-guard` — medium
36. `detection-emulation-validation` — medium (tracked UIW #179)
37. `zeek-detection-scripts` — medium
38. `watcher-coverage` — medium
39. `NEW-ci-action-pinning` — medium
40. `dependency-pinning-broker` — medium
41. `intel-match-alerting` — low
42. `rule-quality-signals` — low (mis-tag sub-claim already fixed on `chore/audit-remediation`; UUID/author remains)
43. `response-audit-trail` — low
44. `pipeline-tests` — low
45. `NEW-input-validation-ingest` — low
46. `NEW-compose-availability-hardening` — low (restart policies already fixed on `chore/audit-remediation`; `mem_limit` remains)
47. `llm-egress-sanitisation` — low

---

## Workstream A — Broker & Agent Authentication (both criticals)

**Status: DONE.** Merged to `main` via PR #205 (2026-07-11). All 12 items below implemented; full test suite 63/63 passing.

**Files:** `scripts/hive-mind-broker/app.py`, `scripts/hive-mind-broker/dispatcher.py`, `scripts/setup/ai_agent/agent_app.py`. None of these were touched by `chore/audit-remediation` — this is a clean slate.

**Contains:** `agent/broker-privileged-endpoint-auth` (critical), `broker-hmac-default-secret` (critical), `broker-hmac-replay-protection` (high), `agent-hmac-replay-protection` (high), `ssh-host-key-verification` (high), `exclusion-list-enforcement` (high), `NEW-actuator-input-validation` (high), `NEW-broker-tenant-scoping` (medium), `approval-double-execution-guard` (medium), `response-audit-trail` (low), `es-tls-verify-fallback` (medium, same file as the auth fix — bundle it in), `slo-failclosed-measurement` (medium, adjacent file `slo_metrics.py`, cheap to bundle).

**Fix approach:**
1. Port the legacy `_require_signature()` gate onto `/approve`, `/pending`, `/weekly-report` in `agent_app.py`, and the equivalent `_verify()` gate onto `/approve`, `/pending` in the broker's `app.py` — legacy already has working reference implementations at `Suburban-SOC/scripts/setup/ai_agent/agent_app.py:180-196` and `Suburban-SOC/scripts/hive-mind-broker/app.py:63-106`.
2. Replace the broker's `HMAC_SECRET = os.getenv("HIVE_MIND_SECRET", "default_dev_secret")` with legacy's empty-default + fail-closed-503 pattern (`Suburban-SOC/scripts/hive-mind-broker/app.py:20-22,75-77`).
3. Port timestamp-window + nonce-cache replay protection onto both the agent's and broker's signature verification, from legacy's reference implementation (`agent_app.py:112-118,129-177`; `broker/app.py:23-29,83-106`).
4. Restore `known_hosts` pinning in `dispatcher.py` (legacy: `dispatcher.py:34-47,138`) instead of the current hardcoded `known_hosts=None`.
5. Restore fail-closed exclusion-list handling (raise-on-unreadable, not catch-and-return-empty) in both `dispatcher.py` and `agent_app.py`, plus CIDR/IPv6-aware matching (legacy: `agent_app.py:300-365`; `dispatcher.py:50-105`).
6. Add IP-format validation (`validate_ip`/`ipaddress`) before `build_nft_command` constructs the SSH command string (legacy: `dispatcher.py:118-120`).
7. Restore tenant-scoped dispatch (`get_routers_for_tenant`) instead of blocking across all routers.
8. Restore resolved-ID subtraction on the agent's `/approve` (already present on the broker side — just port the same logic to the agent).
9. `es-tls-verify-fallback`: change `ES_VERIFY = ES_CA if (ES_CA and Path(ES_CA).is_file()) else False` back to erroring/defaulting-true rather than silently downgrading, per legacy's `agent_app.py:54-60`.
10. `slo-failclosed-measurement`: restore `MetricUnavailable`-raises-and-scores-as-breach behavior in `slo_metrics.py`, and the non-zero exit code on total outage (legacy: `slo_metrics.py:63-68,217-221`).

**Why first:** these are the only findings rated critical, they gate whether `ci-soar-merge-gates` (Workstream C) can close, and — per the audit's open questions — the broker isn't currently deployed, so fixing this now is low-risk (no live system to break) and removes the blocker before any future broker-integration work (UIW #94/#181) ships it live.

---

## Workstream B — Logstash Pipeline Hardening

**Status: DONE.** Merged to `main` via PR #206 (2026-07-11). All 8 items below implemented; reviewed by security-auditor + code-reviewer + tester-debugger and all findings from that pass fixed inline (mTLS client-auth enforcement was missing despite the SAN/CA wiring being correct; `generate_certs.sh`'s idempotency gate would have silently skipped generating the new Logstash/Filebeat certs on any already-deployed host — both fixed and re-verified end-to-end). Two pre-existing bugs incidentally fixed while in these files (not part of the original 8): a dead GeoIP enrichment block referencing nested `[source][ip]` against a pipeline that only ever produces flat `source.ip`, and PII-stripping being a structural no-op on the network-tap ingest path (parsed JSON survived whole under `[network_parsed]`, only allowlisted subfields were ever extracted from it).

**Known follow-ups, not fixed here (tracked, don't block merge):**
- `NEW-logstash-cert-san-scope`: the Logstash server cert's SAN list only covers `logstash`/`localhost`/`127.0.0.1`; remote shippers reaching it by LAN hostname/IP can't validate under `ssl.verification_mode: full` and the documented workaround (`FILEBEAT_SSL_VERIFY=none`) reopens a MITM window. Needs per-deployment SAN configuration in `generate_certs.sh`, not resolvable generically.
- `NEW-ioc-domain-coverage-gap`: the retired `soar_quarantine_alert.json` watcher matched IOCs by domain (Zeek's own intel framework) as well as IP; the replacement Logstash `CRITICAL_THREAT` tag only matches IP indicators in `threat_intel.yml`. A domain-only hit with no corresponding bad IP triggers neither path. Needs a domain-keyed lookup added to the Logstash `translate` stage.
- `NEW-quarantine-json-redaction`: the `message`-field secret-redaction regex was hardened (JSON `"key":"value"` coverage, non-greedy value boundary) but is still text-pattern matching, not JSON-structure-aware — it's a best-effort backstop for the quarantine index, not a guarantee.

**Files:** `scripts/setup/configs/logstash/logstash.conf` (authoritative, deployed) and `configs/logstash.conf` (orphaned duplicate — fix both or delete the duplicate and fix one).

**Contains:** `beats-logstash-mtls` (high), `logstash-outbound-alert-signing` (high), `es-superuser-usage` (high, tracked UIW #180), `watcher-agent-auth-wiring` (high), `pipeline-dlq-persistence` (medium), `parse-failure-quarantine` (medium), `pii-stripping-ingest` (medium), `NEW-input-validation-ingest` (low).

**Fix approach:**
1. Add TLS + required client-cert auth to the Beats input block (legacy reference: `Suburban-SOC/configs/logstash.conf:6-13`), and matching `ssl.*` client config in `configs/network/filebeat.yml`/`configs/server/filebeat.yml`/`configs/server/winlogbeat.yml`.
2. Add a signed `/alert` HTTP output to the pipeline (HMAC over `ts+body`, matching whatever scheme Workstream A restores on the agent side) — legacy reference: `Suburban-SOC/configs/logstash.conf:428-447,521-536`. Once this exists, `soar_quarantine_alert.json` and `hive_mind_bruteforce.json` (the two misconfigured Watcher sources) can either be retired or fixed to send a real computed signature instead of a missing/placeholder one.
3. Change the ES output credential from `elastic`/`ELASTIC_PASSWORD` to a least-privilege writer account — this depends on Workstream E creating that account first.
4. Add a `logstash.yml` with `queue.type: persisted` and `dead_letter_queue.enable: true`, backed by a durable named volume, plus the docker-compose mount for it (legacy: `Suburban-SOC/configs/logstash.yml:19-29`).
5. Add `_grokparsefailure`/`_jsonparsefailure` tagging and a conditional quarantine-index output (legacy: `configs/logstash.conf:342-347,463-473`).
6. Add `remove_field`/`gsub`-redaction for auth headers, cookies, and credential-pattern strings (legacy: `configs/logstash.conf:354-378`).
7. Anchor the sshd grok pattern, add `timeout_millis`, and add tenant-field default/lowercase handling (legacy: `configs/logstash.conf:283-304`).

**Note:** `chore/audit-remediation`'s Logstash changes (ECS field-mapping fixes) are unrelated and don't conflict — that work can land independently of this workstream.

---

## Workstream C — CI/CD Security Gates

**Status: DONE.** Merged to `main` via PR #207 (2026-07-11). All items below implemented, plus `container-user-privilege` (Workstream G item 2) pulled forward and fixed on the spot when the new Trivy IaC gate caught it on the first CI run (`ai_agent/Dockerfile` now runs as non-root `appuser`, uid 10001). All items below addressed: `secret-scan.yml` (gitleaks, full-history), `security-scan.yml` (Trivy image scan — `ai-agent` only, `hive-mind-broker` has no Dockerfile yet, out of scope until it's containerized — plus Trivy IaC scan and pip-audit for both requirements files), all workflow `uses:` lines SHA-pinned, `ci.yml`'s `python-quality`/pytest step now blocking (63/63 passing, `continue-on-error` removed). `ruff` deliberately left non-blocking — pre-existing lint violations outside this workstream's scope. **`NEW-weasyprint-cve-2026-49452` (medium, tracked exception — not blocking):** pip-audit surfaced an unfixed CVE-2026-49452 (CSS injection, SSRF potential via `url()`) in `weasyprint==68.0` (`scripts/setup/ai_agent/requirements.txt`); no patched release exists yet. Suppressed in `security-scan.yml` via `--ignore-vuln CVE-2026-49452` (2026-07-11) rather than left unaudited, so the gate stays green but the exception is visible in the workflow file itself. **Reachability check, not just a paper CVE:** `weekly_ciso_report.py`'s `Template(_HTML_TEMPLATE)` has no `autoescape`, and the LLM-generated `narrative` field it renders (`generate_executive_summary`, fed by aggregate alert data that can include attacker-influenced log content — hostnames, usernames) reaches WeasyPrint's HTML renderer unescaped. This overlaps `llm-egress-sanitisation` (Workstream H) — the compensating fix (`autoescape=True` on the Jinja2 template) closes the injection path independent of whether/when weasyprint itself ships a patch, and should be picked up together with that item. Remove the pip-audit suppression once a fixed weasyprint version is available.

**Files:** `.github/workflows/` (new workflows needed), `tests/unit/` (expand existing).

**Contains:** `ci-secret-scanning` (high), `ci-image-iac-scanning` (high), `ci-dependency-audit` (high), `ci-soar-merge-gates` (high), `agent-unit-tests` (high, partial), `dac-ci-gates` (high, partial, tracked UIW #178), `NEW-ci-action-pinning` (medium).

**Fix approach:**
1. Add a gitleaks (or equivalent) workflow, full-history, every push/PR — legacy reference: `Suburban-SOC/.github/workflows/secret-scan.yml`.
2. Add Trivy image + IaC/compose scanning, exit-1 on CRITICAL — legacy: `Suburban-SOC/.github/workflows/security-scan.yml:36-71`.
3. Add pip-audit on PR + weekly cron — legacy: `security-scan.yml:19-34`.
4. **Blocked on Workstream A:** expand `tests/unit/test_agent_app.py` to cover HMAC replay protection and the privileged-endpoint auth gate once those exist, and make the existing `ci.yml` `python-quality` job blocking (remove `continue-on-error`/`|| true`) — legacy reference for scope: `Suburban-SOC/tests/ai_agent/test_alert_auth.py`, gated by `Suburban-SOC/.github/workflows/soar-tests.yml:17-49`.
5. **Blocked on Workstream D (conversion fidelity):** extend the existing `sigma-validation` job (already a real hard gate on `chore/audit-remediation`) to also assert every rule converts to a valid Elastic detection rule, once `translate_rules.py` does real conversion — legacy: `detections.yml:36-61`.
6. Pin all workflow actions (new and existing) to commit SHAs instead of `@v4` tags.

**Note:** `chore/audit-remediation` already added a `ci.yml` with a real Sigma field/tag-completeness gate and a report-only lint/test job — build on that file rather than replacing it.

---

## Workstream D — Detection Content Restoration

**Files:** `rules/sigma/`, `rules/elastic/threshold/` (currently absent), `scripts/setup/translate_rules.py`, `configs/zeek/`, `rules/elastic_watcher/`.

**Contains:** `sigma-rule-coverage` (high, tracked UIW #173), `attack-technique-coverage` (high, tracked UIW #178), `dac-conversion-fidelity` (high, tracked UIW #175/#102), `elastic-threshold-rules` (high), `detection-emulation-validation` (medium, tracked UIW #179), `zeek-detection-scripts` (medium), `watcher-coverage` (medium), `rule-quality-signals` (low, UUID/author only — mis-tag already fixed on `chore/audit-remediation`), `intel-match-alerting` (low).

**Fix approach:**
1. This is the largest single body of work in the plan — the team's own tracked issues (UIW #173–#179) already sequence most of it: inventory/classify the 25 dropped Sigma rules (#173), triage ECS field mappings (#174), resolve the `translate_rules.py` retire-vs-fix decision (#175 — note `chore/audit-remediation`'s new docstring already defers this to issue #110, so that decision may already be made; confirm), fix the RDP mis-tag (#176 — already done on `chore/audit-remediation`, just needs merging), deploy rules to the SO `local-sigma` path (#177), retarget the four-gate CI at SO's ES (#178 — Workstream C picks this up once conversion is real), validate kept rules against live SO data (#179).
2. Implement real Sigma→Elastic query translation in `translate_rules.py` (or adopt a pySigma Elasticsearch backend directly, replacing the placeholder) — this is the highest-leverage single fix in this workstream since it's a prerequisite for `dac-ci-gates` fully closing in Workstream C.
3. Re-add the 3 threshold NDJSON rules (bruteforce-failed-logons, source-spray, explicit-cred-sweep) — legacy reference: `Suburban-SOC/rules/elastic/threshold/`.
4. Restore `scan-detection.zeek` (T1046 port-scan notice) — legacy: `Suburban-SOC/scripts/setup/configs/zeek/scan-detection.zeek:17-78`.
5. Restore `intel_feed_stale.json` (detection-health Watcher) and the live Zeek Intel-framework match path in the Logstash config (ties into Workstream B).
6. Restore `emulation_telemetry.map` + a validator that checks emulation→rule tag alignment, CI-gated (legacy: `Suburban-SOC/tests/validate_emulation_map.py`).
7. Replace placeholder repeating-digit UUIDs with real UUIDv4s and add `author:` fields to the 10 existing rules (and any restored from #1).

**Sequencing:** steps 3–7 can happen independently and in parallel; step 2 is the one true dependency for Workstream C.

---

## Workstream E — Least-Privilege Elasticsearch Accounts

**Status: Implemented, pending review/merge.** Branch `fix/workstream-e-least-priv-es`. Index patterns were adjusted from legacy's during the port — this repo's actual indices are `logstash-security-*` (not bare `logstash-*`), and `asset-inventory-*`/`threat-intel-*` don't exist here at all (legacy's separately-evolved Zeek-file-ingestion/tenant architecture; threat intel here is a Logstash-side YAML dictionary, not an ES index) — dropped rather than granted on indices that don't exist. `NEW-agent-es-transport` turned out to be a live bug, not just a hardening gap: `agent_app.py`'s own ES-write paths (`soar-actions-<tenant>` audit trail, `soc-audit-<tenant>` tamper-evident log) already expected `ES_HOST`/`ES_USER`/`ES_PASS`/`ES_CA`, but nothing in `docker-compose.yml` set them and no certs volume was mounted — `ES_PASS` defaulted empty and `ES_CA`'s default path didn't exist in the container, so both writes were silently failing (caught, logged, non-fatal) on every deploy. Also found and fixed along the way: `provision_soc_agent.sh` independently hand-defined the `soc_agent_cases` role inline via the Kibana role API, a second, divergence-prone copy of what's now the single committed JSON — refactored it to depend on `apply_roles.sh` having applied that role first.

Reviewed by security-auditor + code-reviewer; the one MEDIUM finding was applied before commit — the initial draft shared one `logstash_internal` account between Logstash and the agent (matching legacy exactly), but the reviewer correctly flagged that as collapsing two trust boundaries: Logstash ingests untrusted network data, so giving it `soc_audit_appender` would let a compromised pipeline forge entries in the tamper-evident `soc-audit-*` trail, and giving the agent `logstash_writer`'s `write`+`manage` would hand it destructive index-admin reach over `logstash-security-*` it never uses. Split into two accounts instead: `logstash_internal` (role: `logstash_writer`, trimmed to `create_index`+`create` on `logstash-security-*` only) and a new `soc_agent_writer` (roles: new `soar_actions_writer` + `soc_audit_appender`) — `AGENT_ES_USER`/`AGENT_ES_PASS` in docker-compose.yml, separate from Logstash's. Also applied: `curl -k` TLS-verification-disabled fallback replaced with a hard fail in every script that carries the bootstrap superuser credential (`apply_roles.sh`, `provision_es_service_accounts.sh`, `provision_soc_agent.sh` — matches `agent_app.py`'s own fail-closed stance, which the warn-and-continue fallback contradicted); JSON request bodies built via `python3 json.dumps` instead of raw shell interpolation (a password containing `"`/`\` could otherwise corrupt the payload or, worst case, smuggle extra JSON keys); dropped `manage_index_templates` (a cluster-wide privilege) from `soc_detection_engineer`, a read-only human role that doesn't need it; added `-S`/`-f` to `curl -s` calls so a network-level failure surfaces an actual error instead of an unexplained `set -e` exit.

**Files:** `configs/elasticsearch/roles/*.json` (new), `scripts/setup/apply_roles.sh` (new), `scripts/setup/provision_es_service_accounts.sh` (new), `scripts/setup/provision_soc_agent.sh`, `scripts/setup/docker-compose.yml`, `scripts/setup/.env.example`.

**Contains:** `es-role-definitions` (medium, tracked UIW #180), `es-least-priv-users` (medium, tracked UIW #180), `NEW-agent-es-transport` (medium).

**Fix approach:**
1. Port legacy's 7 committed role-definition JSONs and `apply_roles.sh` pattern (`Suburban-SOC/configs/elasticsearch/roles/`, `Suburban-SOC/scripts/setup/apply_roles.sh`) — this directly unblocks Workstream B's `es-superuser-usage` fix (Logstash needs a `logstash_writer`-equivalent role to authenticate as) and `slo_metrics`'s own superuser warning.
2. Note: `chore/audit-remediation`'s new `provision_kibana_system.sh` solves a different, narrower problem (Kibana's own service-account bootstrap) — keep it, it's not redundant with this work.
3. Mount a certs volume into the `ai-agent` compose service and set `ES_CA`/`ES_PASS` once the new least-privilege account exists (legacy: `Suburban-SOC/scripts/setup/docker-compose.yml:413-416,447-448`).

---

## Workstream F — Credential & Secrets Hygiene

**Status: Partially done, one item genuinely blocked.**
- `dependency-pinning-broker`: **DONE**, pending review/merge. `scripts/hive-mind-broker/requirements.txt` pinned to legacy's already-vetted versions (`fastapi==0.138.0`, `starlette==1.3.1` — the CVE-2026-48817/48818/54282/54283-fixed floor, `uvicorn==0.34.0`, `pyyaml==6.0.2`, `asyncssh==2.18.0`, `httpx==0.28.1`); `pytest` dropped from the file (test-only, already installed separately in `ci.yml`, confirmed no runtime code imports it). Installed clean in a fresh venv and the full 63-test suite passed against the pinned versions before committing.
- `cert-lifecycle`: **not applicable as originally scoped — investigated, no code change made.** Legacy's `ALLOW_STANDALONE_CERTS` guard exists because legacy's `docker-compose.yml` runs a one-shot `setup` service that mints a SEPARATE Elastic-certutil CA into the same shared `certs` volume `generate_certs.sh` also writes to — two competing cert sources that can silently desync. This repo's `docker-compose.yml` has no such service; `generate_certs.sh` is the sole, intended source of truth for certs here (confirmed via every reference to it in `.env.example`, `SOP-022`, the provisioning scripts, and the compose file's own top-of-file comment). Porting the guard would add friction to the only correct way to set up this repo with no real hazard behind it. Closing this as "investigated, doesn't apply" rather than force-fitting an irrelevant port.
- `committed-credential-rotation` (high, tracked UIW #191): **owner action, not touched.** See item 1 below — untouched, no code change attempted.

**Contains:** `committed-credential-rotation` (high, tracked UIW #191 — scope now narrowed), `cert-lifecycle` (medium — not applicable here, see above), `dependency-pinning-broker` (medium — DONE).

**Fix approach:**
1. **Owner action required, not a code change:** run `git filter-repo` or BFG against the full repository history to remove the historical `elastic` credential string, then force-push the rewritten history and have every clone/fork re-clone. This is exactly what commit `f3a1454`'s own message flags as still outstanding. Coordinate carefully — this is the one genuinely irreversible/disruptive action in this entire plan and needs explicit team sign-off and a maintenance window, not a routine PR.
2. Restore the `ALLOW_STANDALONE_CERTS` opt-in guard in `generate_certs.sh` to prevent accidental CA/cert overwrite (legacy: `Suburban-SOC/scripts/setup/generate_certs.sh:31-42`).
3. Pin `scripts/hive-mind-broker/requirements.txt` to specific versions, restoring the `starlette==1.3.1` CVE-fixed floor (legacy: `Suburban-SOC/scripts/hive-mind-broker/requirements.txt:4-11`).

---

## Workstream G — External Exposure & Container Hardening

**Status: DONE.** Merged to `main` via PR #208 (2026-07-11). Reviewed by security-auditor + code-reviewer, both cleared it with one condition each, both applied: ES `mem_limit` raised 3g→4g after the reviewer flagged the 2g heap was 67% of the cap, risking the cgroup OOM-killer defeating the cap's own purpose; SOP-022/preflight.sh's manual-run instructions changed from `--host 0.0.0.0` to `127.0.0.1` so the doc-driven path matches the hardened container posture instead of silently bypassing it. Also dropped the obsolete `version: '3.8'` compose key while in the file (was producing a warning on every `up`/`config`, zero functional effect).

**Files:** `scripts/setup/docker-compose.yml`, `scripts/setup/ai_agent/Dockerfile`.

**Contains:** `port-binding-agent-broker` (high — DONE, loopback-only publish; the broker compose service itself stays deferred to UIW #94/#181), `container-user-privilege` (high — **DONE**, pulled forward to `fix/workstream-c-ci-security-gates` 2026-07-11: Workstream C's new Trivy IaC gate (`security-scan.yml`) caught `DS-0002` on `ai_agent/Dockerfile` immediately, so item 2 below was fixed on the spot rather than left red pending a full Workstream G pass; build-and-run verified locally, non-root `appuser` confirmed via `id`), `NEW-compose-availability-hardening` (low — DONE, `mem_limit` on all 4 services).

**Fix approach:**
1. Change the agent's compose port mapping from `"5000:5000"` to `"127.0.0.1:5000:5000"` (loopback-only), and add a compose service definition for the broker with the same loopback confinement once/if UIW #94/#181 decides to integrate it.
2. Add a non-root `USER` directive to `scripts/setup/ai_agent/Dockerfile` (legacy: `Suburban-SOC/scripts/setup/ai_agent/Dockerfile:28-33`, creates uid 10001 `appuser`).
3. Add `mem_limit` to every compose service (restart policies were already added on `chore/audit-remediation` — just need `mem_limit`, legacy reference: `Suburban-SOC/scripts/setup/docker-compose.yml:177-178`).

---

## Workstream H — Low-Priority Hygiene

**Status: DONE, pending review/merge.**
- `pipeline-tests`: added `tests/pipeline/test_grok_parse_failures.py` (18 tests, ported from legacy's golden-file pattern — a pure-Python re-implementation of the pipeline's parsing logic, not a live-Logstash test), wired into `ci.yml`'s pytest invocation. Writing it surfaced a real gap: this repo's sshd grok block only ever gated on the auth.log file path, unlike legacy's two-stage gate (path + an sshd-process-tag pre-filter) — every sudo/cron/PAM line in auth.log was reaching the grok pattern, failing to match, getting tagged `_grokparsefailure`, and routing to the quarantine index Workstream B built. Fixed in `logstash.conf` (both copies) by adding the missing pre-filter — then review caught that my first pass (a literal `"sshd["` substring check) introduced a NEW, worse gap: OpenSSH 9.8+ (now default on current distros) re-execs auth handling into a `sshd-session[PID]` process, and 10.0+ adds a narrower pre-auth `sshd-auth[PID]` — neither contains the literal `sshd[` substring, so a brute-force attempt against a modern-OpenSSH host would be silently skipped by the new pre-filter entirely (worse than before: previously it at least reached grok, failed, and landed in quarantine as a visible signal). Fixed by broadening both the pre-filter and the grok pattern to `sshd(?:-session|-auth)?\[`, with new test fixtures for both modern tags. Also tightened the test's IP capture (was `[0-9a-fA-F.:]+`, permissive enough to "match" `999.999.999.999`; now real IPv4-octet-range + IPv6-shaped validation) and `user_name` from `.+` to `.*` to match `%{GREEDYDATA}`'s true zero-or-more semantics.
- `llm-egress-sanitisation`: **investigated, no code change — the plan's own "may have been an intentional broadening" concern is correct.** `agent_app.py`'s `_is_hosted_endpoint()` allowlists `host.docker.internal` with an inline comment explaining exactly why: it's the Docker host gateway, i.e. how a container reaches a LOCAL Ollama running on the physical host — and `docker-compose.yml`'s own default `LLM_API_URL` is `http://host.docker.internal:11434/...`. Removing it from the allowlist, as originally proposed, would misclassify this repo's own zero-config default local-LLM path as "hosted egress" and refuse to triage every alert out of the box unless `LLM_ALLOW_HOSTED=true` — a functional regression, not a hardening fix. Closing as verified-correct.
- The other three items (`intel-match-alerting`, `response-audit-trail`, `NEW-input-validation-ingest`) are cross-referenced under their primary workstreams and were already addressed there (B and A respectively) — no standalone action needed.

**Contains:** `intel-match-alerting` (low — folds into Workstream D/B), `response-audit-trail` (low — folds into Workstream A), `pipeline-tests` (low — DONE), `NEW-input-validation-ingest` (low — folds into Workstream B), `llm-egress-sanitisation` (low — investigated, no change needed).

**Fix approach:**
1. `pipeline-tests`: restore `test_grok_parse_failures.py`-equivalent coverage once Workstream B adds parse-failure quarantine logic to test against.
2. `llm-egress-sanitisation`: narrow the `_is_hosted_endpoint` allowlist back to exclude `host.docker.internal` unless there's a deliberate reason to keep it (worth a quick team discussion — this one may have been an intentional broadening, not an oversight).
3. The other three items are cross-referenced under their primary workstreams above and don't need standalone tracking.

---

## Suggested execution order across workstreams

1. **A** (both criticals — do this regardless of anything else)
2. **E** (unblocks B's superuser fix)
3. **B** (pipeline hardening)
4. **D** (detection content — can run in parallel with B/E once started; conversion-fidelity fix unblocks C)
5. **C** (CI gates — needs A and D's conversion fix to be meaningful, not just present)
6. **G** (exposure/container — independent, can run anytime)
7. **F** (credential hygiene — the git-history rewrite specifically should be scheduled deliberately, not bundled into a routine sprint)
8. **H** (cleanup, lowest priority, mostly folds into other workstreams' PRs)

This plan does not file GitHub issues or open PRs — it's a roadmap. Let me know if you want any workstream turned into actual tracked issues or a first PR.
