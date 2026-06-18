#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — Master Deficiency Register: Issue Creation
# Repo: voltron-1/UIW-CDPv2
#
# Creates one GitHub issue per deficiency (D-01..D-40) from
#   docs/internal documents/UIW_Master_Implementation_Plan_All_Deficiencies.md
# Each issue is milestoned to its target PI, labelled `type: deficiency` + the
# PI label + a priority derived from severity, and assigned per the doc's Owner.
#
# Issue bodies reflect the AGREED implementation plan (not just the doc text):
#   - OpenSearch migration is mandatory (ES->OpenSearch; ILM->ISM; Cases->index)
#   - Host telemetry via Wazuh HIDS + Sysmon-for-Linux (OSS)
#   - Network telemetry via Suricata AND Zeek (both)
#   - SOAR cut to 2 agents (enrichment + summarization) on a Redis bus
#   - Adversary-in-a-Box engine = Atomic Red Team
#   - Kibana Cases replaced by a soc-cases-<tenant> OpenSearch index + dashboard
#
# Prerequisite: `type: deficiency` label (created inline below with --force).
# Mirrors scripts/agile/create_pi_issues.sh conventions (no board mutation).
#
# Severity -> priority:  blocker/high -> critical ; medium -> high ; low -> low
# Run ONCE — re-running creates duplicates.
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-CDPv2"
TL="voltron-1"       # Tommy Lammers — Lead Architect (Lead/PM owner)
SG="sterlinggarnett" # Sterling Garnett — Security Analyst / Engineer (Eng owner)
IP="cryptgrphy"      # Ishmael Pendleton — Network Engineer / Documentation

# Milestone names (exact)
M1="PI-1: Foundation Assessment"
M2="PI-2: Platform Engineering"
M3="PI-3: Detection Engineering Program"
M4="PI-4: Adversary Validation"
M5="PI-5: Multi-Agent SOAR Core"
M6="PI-6: Student Analyst Operations"

# PI label names (note: differ from milestone names)
L1="PI-1: Foundation Assessment"
L2="PI-2: Platform Engineering"
L3="PI-3: Detection Engineering"
L4="PI-4: Adversary Validation"
L5="PI-5: Multi-Agent SOAR"
L6="PI-6: Student Analyst Ops"

gh label create "type: deficiency" --color "E99695" \
  --description "Remediation item from the Master Deficiency Register (D-01..D-40)" \
  --force >/dev/null 2>&1 || true

# new_issue <title> <milestone> <assignees> <pi_label> <priority> <body>
new_issue() {
  local title="$1" milestone="$2" assignees="$3" pi_label="$4" priority="$5" body="$6"
  local url
  url=$(gh issue create -R "$REPO" \
    -t "$title" \
    -b "$body" \
    -m "$milestone" \
    -l "type: deficiency,${pi_label},priority: ${priority}" \
    -a "$assignees")
  echo "  [created] $title -> $url"
}

echo "============================================================"
echo "  Master Deficiency Register -> GitHub issues (D-01..D-40)"
echo "============================================================"

# ===========================================================================
echo ""; echo "--- A. Planning & Schedule ---"

new_issue "D-01: Master schedule mapping all 7 PIs to calendar weeks" \
  "$M1" "$TL" "$L1" "critical" \
"**Deficiency (Eval P1, blocker):** No master schedule; PI durations (~21-29 wks) untested against the term.

**Fix:** Add a calendar-week schedule table + total rollup, appended to docs/internal documents/UIW_Cyber_Defense_Platform_Implementation_Plan.md (which already lists per-PI durations).

**Acceptance:** Schedule table approved; fits the term with slack.
Source: Master Deficiency Register D-01 (Tranche 1)."

new_issue "D-02: MoSCoW-tag every deliverable" \
  "$M1" "$TL" "$L1" "high" \
"**Deficiency (Eval P1):** No prioritization of deliverables; cuts would be improvised.

**Fix:** Tag every deliverable M/S/C/W in the Implementation Plan doc.

**Acceptance:** Each deliverable tagged Must/Should/Could/Won't.
Source: D-02."

new_issue "D-03: Define thin-thread MVP (1 source -> 1 detection -> 1 alert -> 1 response)" \
  "$M1" "$TL" "$L1" "critical" \
"**Deficiency (Eval P1/P2, blocker):** No early end-to-end proof; risk concentrated late.

**Fix:** Define a thin-thread MVP milestone by PI3-4 — one telemetry source through one Sigma detection to one alert to one manual response. Maps to the existing tests/anomaly_simulation/ + agent_app.py /alert path.

**Acceptance:** MVP milestone with a date in the plan.
Source: D-03 (Tranche 1)."

new_issue "D-04: Allocate PI7 duration + demo dry-run / rehearsal" \
  "$M1" "$TL" "$L1" "high" \
"**Deficiency (Eval Notes):** PI7 has no duration; no demo rehearsal.

**Fix:** Allocate 1-2 wks to PI7 incl. a dry run (the PI-7 milestone exists; add duration + rehearsal slot).

**Acceptance:** PI7 has a duration and a rehearsal slot.
Source: D-04."

new_issue "D-05: One-page PI -> Strategic Objective traceability matrix" \
  "$M1" "$TL" "$L1" "low" \
"**Deficiency (Eval Notes):** No PI->Objective traceability.

**Fix:** One-page matrix; folds into governance/traceability-matrix.md (Framework Alignment WS-D1).

**Acceptance:** Every PI maps to >=1 Strategic Objective.
Source: D-05 (overlaps WS-D)."

new_issue "D-06: Map objectives to NIST CSF 2.0 functions (Govern..Recover)" \
  "$M1" "$TL" "$L1" "low" \
"**Deficiency (Eval Notes):** No explicit NIST CSF 2.0 framing.

**Fix:** CSF mapping paragraph; aligns with governance/nist-csf-2.0-profile.md (Framework Alignment WS-A2) which adds the Govern function.

**Acceptance:** CSF mapping (GV/ID/PR/DE/RS/RC) in the plan.
Source: D-06 (overlaps WS-A2)."

# ===========================================================================
echo ""; echo "--- B. Risk, Governance & Access Control ---"

new_issue "D-07: Living Risk Register" \
  "$M1" "$TL" "$L1" "high" \
"**Deficiency (Eval P6):** No forward-looking risk register.

**Fix:** Create governance/risk-register.md (Framework Alignment WS-A1 path) — HW limits, turnover, model perf, ES->OpenSearch migration risk.

**Acceptance:** Register live with >=6 risks + mitigations.
Source: D-07 (overlaps WS-A1)."

new_issue "D-08: Student-operator access policy + data-handling policy" \
  "$M1" "$TL" "$L1" "high" \
"**Deficiency (SOC):** Govern plane unaddressed; no data-handling/RBAC policy.

**Fix:** governance/policies/access-control.md + data-handling.md (Framework Alignment WS-A1). Pairs with D-09 (real OpenSearch roles).

**Acceptance:** Written, reviewed policy.
Source: D-08 (overlaps WS-A1)."

new_issue "D-09: Map student roles to real OpenSearch Security roles (Observer/Analyst/Hunter)" \
  "$M6" "$SG,$TL" "$L6" "high" \
"**Deficiency (SOC):** Roles on honor system; no enforced permissions.

**Fix (OpenSearch):** Define observer/analyst/hunter in configs/opensearch/security/roles.yml + roles_mapping.yml (OpenSearch Security plugin, replacing Elastic roles). Follow the least-priv pattern the agent already uses (logstash_internal, soc_audit_appender). Provision via scripts/setup/provision_soc_agent.sh.

**Acceptance:** 3 roles enforced in OpenSearch.
Source: D-09 (overlaps WS-B2)."

new_issue "D-10: Segment the attack range from SOC / campus production" \
  "$M1" "$SG,$TL" "$L1" "critical" \
"**Deficiency (SOC, blocker):** Emulation range not isolated; pivot risk.

**Fix:** Isolated VLAN/VM for emulation; document the boundary in governance/policies/attack-range-isolation.md + extend docs/network_topology.md. Hooks to scripts/setup/isolate.sh and the hive-mind-broker per-tenant inventory. Links D-22.

**Acceptance:** Emulation segment provably isolated + documented.
Source: D-10 (Tranche 1)."

# ===========================================================================
echo ""; echo "--- C. Data Ingestion & Normalization ---"

new_issue "D-11: Adopt ECS as the normalization contract" \
  "$M2" "$SG,$TL" "$L2" "critical" \
"**Deficiency (SOC, Purple, blocker):** No normalization schema; field sprawl.

**Fix:** Document ECS as the contract in docs/detections/ecs-normalization-contract.md and fill gaps in configs/logstash.conf (the mutate{rename} blocks already map Zeek->ECS informally). All Suricata + Zeek + Wazuh telemetry normalizes to the same ECS fields pre-index.

**Acceptance:** All telemetry normalized to ECS pre-index.
Source: D-11 (Tranche 1)."

new_issue "D-12: Name + deploy the collection/shipping tier" \
  "$M2" "$SG,$TL" "$L2" "high" \
"**Deficiency (SOC):** Shipping tier not named.

**Fix:** Tier is Filebeat + Logstash (configs/*/filebeat.yml, configs/logstash.conf) — name and document it; add Wazuh + Suricata shippers.

**Acceptance:** Shipping tier named + deployed.
Source: D-12."

new_issue "D-13: Enable high-value telemetry (process+cmdline, identity/auth, PowerShell)" \
  "$M2" "$SG,$TL" "$L2" "critical" \
"**Deficiency (Red, Purple, blocker):** Missing process/cmdline, identity/auth, script-block telemetry.

**Fix (Wazuh + Sysmon-for-Linux OSS):** Deploy Wazuh HIDS + Sysmon-for-Linux via scripts/setup/install_wazuh.sh, configs/wazuh/ossec.conf, configs/sysmon/sysmon-linux-config.xml; add a Wazuh service to docker-compose.yml; map Wazuh/Sysmon fields -> ECS in the endpoint_logs branch of configs/logstash.conf (lines 61-81). Covers process+cmdline, Linux auth (4624/4625-equivalent), and script-block-equivalent activity.

**Acceptance:** All source classes indexed + verified for >=3 hosts.
Source: D-13 (Tranche 1)."

new_issue "D-14: Sensor-health / heartbeat telemetry (dead shipper alarms)" \
  "$M2" "$SG,$TL" "$L2" "high" \
"**Deficiency (Red, Purple):** Dead shipper is silent.

**Fix:** Use Wazuh agent connection-status as the heartbeat; index to soc-sensor-health-* + an alert rule. Pairs with the D-21 log-volume->0 anomaly and the D-27 pipeline-blinding test.

**Acceptance:** A dead source raises an alert.
Source: D-14 (Tranche 2)."

new_issue "D-15: Decide Cyber & Physical Systems Monitoring (scope or defer)" \
  "$M1" "$TL" "$L1" "high" \
"**Deficiency (Eval P5):** Promised in the vision but no PI delivers it.

**Fix:** Decision — scope into a PI or move to README Deferred Scope. Record the decision (ADR).

**Acceptance:** Decision recorded; no orphan promise.
Source: D-15 — DECISION NEEDED."

new_issue "D-16: Index lifecycle (ISM) rollover + delete policy + disk budget" \
  "$M2" "$SG,$TL" "$L2" "high" \
"**Deficiency (SOC, Eval P5):** No retention policy; lab disk fills.

**Fix (OpenSearch ISM):** Create configs/opensearch/ism/{logstash-security,soar-actions,soc-audit}-ism.json. The agent code (agent_app.py log_soar_action/write_audit) already ASSUMES these lifecycle policies exist but they were never version-controlled.

**Acceptance:** ISM policy active; disk projection documented.
Source: D-16 (Tranche 2)."

# ===========================================================================
echo ""; echo "--- D. Detection Engineering (Detection-as-Code) ---"

new_issue "D-17: Git branch/PR/review workflow for Sigma rules" \
  "$M3" "$SG,$TL" "$L3" "high" \
"**Deficiency (SOC, Eval P5):** Detection repo has no Git workflow.

**Fix:** rules/sigma/README.md + .github/PULL_REQUEST_TEMPLATE.md (+ optional CODEOWNERS).

**Acceptance:** Rules live in Git with PR review.
Source: D-17 (overlaps WS-C3)."

new_issue "D-18: CI validation for rules (sigma-cli lint + convert + test)" \
  "$M3" "$SG,$TL" "$L3" "critical" \
"**Deficiency (SOC, Purple, Eval P5, blocker):** No CI validation for rules.

**Fix:** New .github/workflows/validate-rules.yml runs sigma-cli lint+convert on every PR touching rules/sigma/. Rewrite scripts/setup/translate_rules.py — it currently hardcodes the OLD repo path (/home/tjlam/projects/UIW-Cyber-Defence-Platform/...) and only does a mock conversion; make paths repo-relative and target the OpenSearch backend.

**Acceptance:** CI runs on every PR and blocks bad rules.
Source: D-18 (Tranche 1)."

new_issue "D-19: FP-storm gate before deploy" \
  "$M3" "$SG,$TL" "$L3" "critical" \
"**Deficiency (Purple, blocker):** No false-positive gate before deploy.

**Fix:** New tests/detection/fp_gate.py validates a new rule against a normal-telemetry baseline; wired into validate-rules.yml to block on an FP threshold. Reuses the ES/OpenSearch count-query pattern in tests/anomaly_simulation/verify_detections.py (build_checks).

**Acceptance:** Deploy blocked if FP rate > threshold.
Source: D-19 (Tranche 1)."

new_issue "D-20: Mandate ATT&CK technique tag per rule (front-matter)" \
  "$M3" "$SG,$TL" "$L3" "low" \
"**Deficiency (SOC):** No rule metadata standard.

**Fix:** Rules already carry attack.* tags (e.g. rules/sigma/proc_creation_win_lsass_dump.yml). ENFORCE them: extend translate_rules.py validate_rule() REQUIRED_FIELDS to require tags + attack.*; also add nist_csf:/iso27001: (WS-D2). Gate in validate-rules.yml.

**Acceptance:** Coverage dashboard auto-populates from tags.
Source: D-20 (overlaps WS-C/D)."

new_issue "D-21: Add >=1 behavioral / anomaly detection" \
  "$M3" "$SG,$TL" "$L3" "high" \
"**Deficiency (Red):** Pure-signature ceiling; no behavioral detection.

**Fix:** Add a behavioral detection — new parent-child process / first-seen logon hour / log-volume->0 — as rules/sigma/anomaly_first_seen_logon.yml or an OpenSearch Anomaly Detection job. Note overlap with D-14.

**Acceptance:** >=1 behavioral detection firing.
Source: D-21 (Tranche 2)."

# ===========================================================================
echo ""; echo "--- E. Adversary Emulation & Validation Loop ---"

new_issue "D-22: Name the Adversary-in-a-Box engine + isolation boundary" \
  "$M4" "$SG,$TL" "$L4" "critical" \
"**Deficiency (Eval P5, blocker):** Adversary-in-a-Box never defined; no isolation.

**Fix:** Engine = Atomic Red Team (best fit for the existing tests/anomaly_simulation/sim_*.sh and the re-emulation regression loop). Document in docs/playbooks/adversary-in-a-box.md with the isolation boundary (links D-10). Caldera deferred for the D-23 named-actor chain.

**Acceptance:** Engine named; isolation documented.
Source: D-22 (Tranche 1)."

new_issue "D-23: Emulate a named actor's full kill-chain + assume-breach" \
  "$M4" "$SG,$TL" "$L4" "high" \
"**Deficiency (Red):** Validation only tests own replay library (false confidence).

**Fix:** New tests/anomaly_simulation/sim_named_actor_chain.sh + run_all.sh entry; run a full named-actor chain unscripted (Caldera optional here).

**Acceptance:** >=1 named-actor chain run unscripted.
Source: D-23 (Tranche 2)."

new_issue "D-24: Telemetry-presence check between emulate and detect" \
  "$M4" "$SG,$TL" "$L4" "critical" \
"**Deficiency (Red, Purple, blocker):** No telemetry-presence check between emulate and detect.

**Fix:** Extend tests/anomaly_simulation/verify_detections.py (Check dataclass) to record presence Y/N PER TTP and emit a structured result feeding the D-26 scorecard. Closest-to-done loop piece — it already counts expected events.

**Acceptance:** Presence Y/N recorded per TTP.
Source: D-24 (Tranche 1)."

new_issue "D-25: Re-emulation regression after a rule is written" \
  "$M4" "$SG,$TL" "$L4" "critical" \
"**Deficiency (Red, Purple, blocker):** No re-emulation regression to confirm a fix works.

**Fix:** New tests/anomaly_simulation/regression.sh re-runs the atomic test after a rule is written and confirms the ALERT fires (not just telemetry present) — needs an alert-presence query vs. the current event-presence query.

**Acceptance:** Re-run is an explicit PI4 exit criterion.
Source: D-25 (Tranche 1)."

new_issue "D-26: Four-column coverage table (Technique | Telemetry Y/N | Alert Y/N | Rule Ref)" \
  "$M3" "$SG,$TL" "$L3" "high" \
"**Deficiency (Red, Purple, Eval P3):** Coverage implied binary; no detected/partial/missed.

**Fix:** docs/detections/coverage-scorecard.md auto-fed from D-24 output + scripts/setup/generate_attack_layer.py + rules/attack/navigator-layer.json (Framework Alignment WS-C1/C2). Generator logic half-exists in translate_rules.py generate_attack_matrix().

**Acceptance:** Table is the centerpiece artifact, auto-fed.
Source: D-26 (Tranche 2, overlaps WS-C)."

new_issue "D-27: Detect pipeline-blinding (cleared logs / killed agent)" \
  "$M4" "$SG,$TL" "$L4" "high" \
"**Deficiency (Red):** No detection of self-tampering / silence.

**Fix:** New tests/anomaly_simulation/sim_pipeline_blinding.sh emulates cleared logs / killed agent; confirms the platform notices silence end-to-end via the existing rules/sigma/proc_creation_win_clear_event_logs.yml rule + the D-14 Wazuh heartbeat.

**Acceptance:** Blinding attempt raises an alert.
Source: D-27 (Tranche 2)."

# ===========================================================================
echo ""; echo "--- F. AI / SOAR Tier ---"

new_issue "D-28: Ollama local-model feasibility spike (go/no-go)" \
  "$M1" "$SG,$TL" "$L1" "critical" \
"**Deficiency (SOC, Eval P2/P4, blocker):** Local-model feasibility unproven on lab HW.

**Fix:** 2-3 day spike: model, GPU/VRAM, latency/alert -> docs/spikes/ollama-feasibility.md. Validates the agent_app.py default (LLM_API_URL host.docker.internal:11434, LLM_MODEL llama3.1). Do in week 1-2; gates the whole AI tier.

**Acceptance:** Spike report with go/no-go + numbers.
Source: D-28 (Tranche 1)."

new_issue "D-29: Cut MAS scope to 2 agents (enrichment + summarization)" \
  "$M5" "$TL" "$L5" "high" \
"**Deficiency (SOC, Eval P4):** Over-scoped at 4 agents.

**Fix (CONFIRMED 2 agents):** Summarization agent = existing analyze_alert_with_ai (agent_app.py:282). Enrichment agent = new CTI/OSINT module. Defer Threat Hunter + Compliance (keep weekly_ciso_report.py as a scheduled report, not an agent). Trim README MAS section 4->2.

**Acceptance:** Scope doc shows 2 core + stretch.
Source: D-29 (Tranche 2). NOTE: overrides the README's 4-agent claim per owner decision."

new_issue "D-30: Justify or cut the Compliance Agent" \
  "$M5" "$TL" "$L5" "low" \
"**Deficiency (SOC, Eval Notes):** Compliance Agent has no compliance regime.

**Fix:** Resolved by D-29 — keep weekly_ciso_report.py as a scheduled CISO report (it already maps detections to NIST CSF), not a standing agent. Record the decision.

**Acceptance:** Decision recorded.
Source: D-30."

new_issue "D-31: Grounding contract — cite source event ID + analyst-verified disclaimer" \
  "$M5" "$SG,$TL" "$L5" "critical" \
"**Deficiency (SOC, Eval P4, blocker):** No grounding contract; hallucination risk; students trust the model.

**Fix:** Modify analyze_alert_with_ai system_prompt (agent_app.py:287) to require every output cite the source event _id; add an 'AI-assisted, analyst-verified' disclaimer to all render paths (send_soc_alert, send_discord_alert, and the new soc-cases-* writer). Key safety item.

**Acceptance:** No ungrounded output shown; disclaimer in UI.
Source: D-31 (Tranche 1)."

new_issue "D-32: Name the Agent Communication Bus (Redis pub/sub)" \
  "$M5" "$SG,$TL" "$L5" "low" \
"**Deficiency (SOC, Eval P4):** Agent Communication Bus undefined.

**Fix (full build-up):** Add a Redis service to docker-compose.yml + a small bus module for pub/sub between the 2 agents (builds the README's bus even at 2 agents).

**Acceptance:** Bus tech specified + working.
Source: D-32."

new_issue "D-33: Define audit logging (what/where/retention)" \
  "$M5" "$SG,$TL" "$L5" "low" \
"**Deficiency (SOC, Eval P4):** Audit logging undefined.

**Fix:** Largely DONE — write_audit() (agent_app.py:559) already appends to soc-audit-<tenant>. Document the schema + retention; retention enforced by the D-16 ISM policy.

**Acceptance:** Audit log schema + retention documented.
Source: D-33."

new_issue "D-34: Measure AI enrichment quality vs analyst baseline" \
  "$M5" "$SG,$TL" "$L5" "high" \
"**Deficiency (Eval P3):** No measurable AI quality criterion.

**Fix:** New tests/ai/enrichment_eval.py measures enrichment vs analyst baseline on >=20 alerts; tracks accuracy + hallucination rate.

**Acceptance:** Metric reported.
Source: D-34 (Tranche 2)."

# ===========================================================================
echo ""; echo "--- G. Resilience, Reproducibility & Recover ---"

new_issue "D-35: Encode the stack as IaC (docker-compose / Ansible)" \
  "$M2" "$SG,$TL" "$L2" "critical" \
"**Deficiency (SOC, Eval P6, blocker):** Hand-built, non-reproducible.

**Fix:** Make docker-compose up work from a clean checkout — the committed scripts/setup/docker-compose.yml currently mounts ./configs/logstash/logstash.conf but the file is at configs/logstash.conf (broken). Migrate the stack to OpenSearch (see D-11/D-16) and add provisioning (scripts/setup/provision_cluster.sh or Ansible).

**Acceptance:** Cohort N+1 can 'up' the stack.
Source: D-35 (Tranche 1)."

new_issue "D-36: Recover plan — snapshot policy + rebuild runbook" \
  "$M2" "$SG,$TL" "$L2" "high" \
"**Deficiency (SOC, Eval P6):** No Recover plan / platform backup.

**Fix (OpenSearch SM):** configs/opensearch/snapshot/sm-policy.json + docs/runbooks/restore.md; test a restore.

**Acceptance:** Restore tested from snapshot.
Source: D-36 (Tranche 2)."

new_issue "D-37: Backup checkpoint before the ELK->OpenSearch migration" \
  "$M2" "$SG,$TL" "$L2" "high" \
"**Deficiency (SOC, Eval P6):** Migration has no rollback.

**Fix:** scripts/setup/backup_before_migration.sh + docs/runbooks/elk-to-opensearch.md documents the rollback path. Run before cutover.

**Acceptance:** Documented rollback path.
Source: D-37 (Tranche 2)."

new_issue "D-38: Architecture Decision Record (ADR) log" \
  "$M1" "$TL" "$L1" "low" \
"**Deficiency (Eval P6):** No ADR log for cohort handoff.

**Fix:** docs/adr/ + docs/adr/0001-record-architecture-decisions.md; capture the OpenSearch-migration, Atomic-Red-Team, 2-agent, and soc-cases-index decisions. Ongoing.

**Acceptance:** ADRs captured per major decision.
Source: D-38 (overlaps WS-D3)."

new_issue "D-39: Rebuild-from-scratch runbook" \
  "$M6" "$SG,$TL" "$L6" "high" \
"**Deficiency (Eval P6):** No rebuild-from-scratch runbook.

**Fix:** docs/runbooks/rebuild-from-scratch.md, validated by a fresh build (depends on D-35 IaC).

**Acceptance:** Runbook validated by a fresh build.
Source: D-39 (Tranche 2)."

# ===========================================================================
echo ""; echo "--- H. Measurable Exit Criteria (cross-cutting) ---"

new_issue "D-40: Attach numeric thresholds to every PI exit criterion" \
  "$M1" "$TL" "$L1" "critical" \
"**Deficiency (Eval P3, blocker):** Exit criteria mostly binary/vague.

**Fix:** Rewrite the vague 'Exit Criteria' in docs/internal documents/UIW_Cyber_Defense_Platform_Implementation_Plan.md using the Master Deficiency Register section 3 numeric metrics (e.g. PI2: >=3 ECS sources, <5 min ingest latency; PI4: >=10 TTPs classified detected/partial/missed).

**Acceptance:** Each PI has >=1 numeric exit metric.
Source: D-40 (Tranche 1)."

echo ""
echo "============================================================"
echo "  All 40 deficiency issues created."
echo "  Add them to the project board with scripts/agile/ tooling."
echo "============================================================"
