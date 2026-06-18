#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — Create New PI Issues
# Repo: voltron-1/UIW-CDPv2
# Creates ~49 new issues across PI-1 through PI-7
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-CDPv2"
TL="voltron-1"       # Tommy Lammers — Lead Architect
SG="sterlinggarnett" # Sterling Garnett — Security Analyst
IP="cryptgrphy"      # Ishmael Pendleton — Network Engineer / Documentation

new_issue() {
  local title="$1"
  local milestone="$2"
  local assignees="$3"
  local labels="$4"
  local body="$5"

  local result
  # The GitHub CLI 'issue create' command natively handles the comma-separated lists for labels and assignees.
  # Use process substitution or here-string for the body to avoid quoting issues.
  result=$(gh issue create -R "$REPO" \
    -t "$title" \
    -b "$body" \
    -m "$milestone" \
    -l "$labels" \
    -a "$assignees" \
    )
  echo "  [created] $result"
}

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-1: Foundation Assessment (Milestone 1)"
echo "========================================================"

new_issue \
  "[Epic] PI-1: Foundation Assessment" \
  "PI-1: Foundation Assessment" \
  "$IP,$TL" \
  "PI-1: Foundation Assessment,type: epic,priority: critical" \
  "## Epic: PI-1 Foundation Assessment

**Lead:** @${IP} (Ishmael Pendleton)
**Support:** @${TL} (Tommy Lammers)
**Duration:** 2–3 Weeks

### Objectives
- Audit the legacy Suburban-SOC / MVP architecture
- Inventory and classify all Sigma detection rules
- Audit telemetry sources for ingestion failures
- Audit existing dashboards for functionality gaps
- Identify all detection and ingestion failures

### Deliverables
- [ ] Current State Architecture Document
- [ ] Detection Inventory
- [ ] Platform Gap Analysis
- [ ] Technical Debt Register

### Exit Criteria (Gate)
All in-scope hosts pass CIS Benchmark Level 2. Known current-state architecture, detection status, and dashboard issues are documented.

### Invariant: Hardening-First
No security component, sensor, or AI agent will be provisioned until this PI passes its gate review."

new_issue \
  "Audit Suburban-SOC MVP architecture and document current state" \
  "PI-1: Foundation Assessment" \
  "$IP,$TL" \
  "PI-1: Foundation Assessment,type: task,priority: critical" \
  "**Owner:** @${IP}, @${TL}
**Priority:** CRITICAL | **PI:** 1

## Description
Perform a full architectural audit of the legacy Suburban-SOC deployment. Document all running components, versions, Docker network topology, and current data flow paths.

## Acceptance Criteria
- [ ] All running containers and services inventoried with versions
- [ ] Current data flow diagram produced (Zeek → Logstash → Elasticsearch → Kibana)
- [ ] Known failures and limitations documented
- [ ] Current State Architecture Document committed to \`docs/\`

## References
UIW CDP Proposal §8: PI-1 Core Technical Objectives"

new_issue \
  "Inventory all Sigma detection rules and classify status" \
  "PI-1: Foundation Assessment" \
  "$SG,$TL" \
  "PI-1: Foundation Assessment,type: task,priority: critical" \
  "**Owner:** @${SG}, @${TL}
**Priority:** CRITICAL | **PI:** 1

## Description
Perform a complete inventory of all existing Sigma rules in the repository. Classify each as: Validated, Broken, Untested, or Deprecated.

## Acceptance Criteria
- [ ] All Sigma rules in \`rules/\` directory catalogued
- [ ] Each rule classified: Validated / Broken / Untested / Deprecated
- [ ] False positive rate noted where known
- [ ] Detection Inventory document produced

## References
UIW CDP Implementation Plan — PI-1 Deliverables: Detection Inventory"

new_issue \
  "Audit telemetry sources (Zeek, Suricata, Wazuh) for ingestion failures" \
  "PI-1: Foundation Assessment" \
  "$SG,$TL" \
  "PI-1: Foundation Assessment,type: task,priority: critical" \
  "**Owner:** @${SG}, @${TL}
**Priority:** CRITICAL | **PI:** 1

## Description
Audit all three telemetry pipeline paths for ingestion failures, parsing errors, and missing field mappings. Identify which data sources are producing usable telemetry.

## Acceptance Criteria
- [ ] Zeek → Logstash → Elasticsearch pipeline verified end-to-end
- [ ] Suricata log forwarding path audited
- [ ] Wazuh agent-to-manager forwarding verified
- [ ] All parse failures and missing ECS fields documented in Technical Debt Register

## References
UIW CDP Proposal §5 Technical Architecture"

new_issue \
  "Audit existing dashboards for functionality gaps" \
  "PI-1: Foundation Assessment" \
  "$SG,$TL" \
  "PI-1: Foundation Assessment,type: task,priority: high" \
  "**Owner:** @${SG}, @${TL}
**Priority:** HIGH | **PI:** 1

## Description
Review all existing Kibana dashboards for broken visualizations, missing data views, or non-functional panels. Produce a gap analysis against the target OpenSearch dashboard requirements.

## Acceptance Criteria
- [ ] All existing Kibana dashboards reviewed
- [ ] Broken or missing panels documented
- [ ] Gap analysis table produced listing: current dashboards vs. required OpenSearch dashboards
- [ ] Priority order for dashboard rebuild established

## References
UIW CDP Implementation Plan — PI-1 Exit Criteria: Known dashboard issues"

new_issue \
  "Document platform gap analysis vs. UIW Cyber Defence Platform requirements" \
  "PI-1: Foundation Assessment" \
  "$IP,$TL" \
  "PI-1: Foundation Assessment,type: task,priority: critical,type: documentation" \
  "**Owner:** @${IP} (lead), @${TL}
**Priority:** CRITICAL | **PI:** 1

## Description
Produce the formal Platform Gap Analysis document comparing the current Suburban-SOC MVP state against all UIW Cyber Defence Platform requirements across PIs 2–7.

## Acceptance Criteria
- [ ] Gap analysis covers: Platform Engineering, Detection Engineering, Adversary Validation, SOAR, Student Ops
- [ ] Each gap rated by severity: Blocking / Major / Minor
- [ ] Technical Debt Register populated with all identified gaps
- [ ] Document committed to \`docs/\`

## References
UIW CDP Proposal §8: PI-1 Mandatory Deliverables"

new_issue \
  "Create Technical Debt Register" \
  "PI-1: Foundation Assessment" \
  "$IP" \
  "PI-1: Foundation Assessment,type: documentation,priority: high" \
  "**Owner:** @${IP}
**Priority:** HIGH | **PI:** 1

## Description
Create and maintain the Technical Debt Register — a living document cataloguing all known architectural debt, workarounds, broken configurations, and deferred fixes identified during the PI-1 audit.

## Acceptance Criteria
- [ ] Register template created in \`docs/\` with columns: Item, Severity, PI Where Resolved, Owner
- [ ] All audit findings from PI-1 tasks entered
- [ ] Register linked from README and project board
- [ ] Register updated as debt items are resolved in subsequent PIs

## References
UIW CDP Implementation Plan — PI-1 Deliverables: Technical Debt Register"

new_issue \
  "[Gate] PI-1 Exit Review: CIS Benchmark Level 2 scan on all in-scope hosts" \
  "PI-1: Foundation Assessment" \
  "$IP,$TL" \
  "PI-1: Foundation Assessment,type: gate-review,priority: critical" \
  "**Owner:** @${IP}, @${TL}
**Priority:** CRITICAL | **PI:** 1 Exit Gate

## Gate Criteria (from UIW CDP Proposal §9)
This issue must be closed before any PI-2 work begins.

### Hard Stop Criteria
- [ ] Every in-scope host passes CIS Benchmark Level 2 scan with zero open critical vulnerabilities
- [ ] External network scans reveal only documented and authorized ports
- [ ] Current State Architecture Document signed off
- [ ] Platform Gap Analysis finalized
- [ ] Technical Debt Register populated

### Disposition on Gate Failure
**Hard Stop.** Software stack deployment (PI-2) is blocked until all host configurations are remediated and this gate passes.

## References
UIW CDP Proposal §9: Verification & Gate Criteria — PI-1"

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-2: Platform Engineering (Milestone 3)"
echo "========================================================"

new_issue \
  "[Epic] PI-2: Platform Engineering" \
  "PI-2: Platform Engineering" \
  "$TL,$SG" \
  "PI-2: Platform Engineering,type: epic,priority: critical" \
  "## Epic: PI-2 Platform Engineering

**Lead:** @${TL} (Tommy Lammers)
**Support:** @${SG} (Sterling Garnett)
**Duration:** 3–4 Weeks

### Objectives
- Migrate all legacy ELK stack components to OpenSearch
- Standardize index naming and telemetry pipelines
- Rebuild security monitoring dashboards
- Update all deployment documentation

### Deliverables
- [ ] Operational OpenSearch Cluster
- [ ] OpenSearch Dashboards
- [ ] Updated Deployment Runbooks

### Exit Criteria (Gate)
Telemetry from all sources visible in OpenSearch. Dashboards render cleanly without manual config. Alerting operational.

### Prerequisite
PI-1 gate must be closed before this PI begins."

new_issue \
  "Migrate Kibana → OpenSearch Dashboards" \
  "PI-2: Platform Engineering" \
  "$TL,$SG" \
  "PI-2: Platform Engineering,type: task,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 2

## Description
Migrate all existing Kibana dashboards and data views to OpenSearch Dashboards. Validate all visualizations render correctly against the new OpenSearch index structure.

## Acceptance Criteria
- [ ] OpenSearch Dashboards container deployed and accessible
- [ ] All critical dashboards migrated: Network Overview, Security Events, Endpoint Activity
- [ ] Data views configured for all active indices
- [ ] No broken visualizations or missing panels
- [ ] Dashboard export saved to \`configs/server/\`

## References
UIW CDP Proposal §5: Visualization Plane — OpenSearch Dashboards"

new_issue \
  "Standardize index naming conventions across all pipelines" \
  "PI-2: Platform Engineering" \
  "$TL,$SG" \
  "PI-2: Platform Engineering,type: task,priority: high" \
  "**Owner:** @${TL}, @${SG}
**Priority:** HIGH | **PI:** 2

## Description
Define and implement a standardized index naming convention for all telemetry sources flowing into OpenSearch. Document the naming schema.

## Acceptance Criteria
- [ ] Index naming schema defined and documented (e.g., \`uiw-zeek-*\`, \`uiw-suricata-*\`, \`uiw-wazuh-*\`)
- [ ] All Logstash pipeline configs updated to use new naming
- [ ] Index templates created in OpenSearch
- [ ] Old index names deprecated and documented in Technical Debt Register

## References
UIW CDP Proposal §5: Single-Source-of-Truth Invariant"

new_issue \
  "Standardize telemetry ingestion pipelines (Logstash → OpenSearch)" \
  "PI-2: Platform Engineering" \
  "$SG,$TL" \
  "PI-2: Platform Engineering,type: task,priority: critical" \
  "**Owner:** @${SG}, @${TL}
**Priority:** CRITICAL | **PI:** 2

## Description
Rebuild and standardize all Logstash pipeline configurations to route telemetry (Zeek, Suricata, Wazuh) into OpenSearch with correct ECS field mappings.

## Acceptance Criteria
- [ ] Logstash → OpenSearch output configured and authenticated
- [ ] Zeek pipeline: all core log types mapped to ECS fields
- [ ] Suricata pipeline: alerts and flow logs indexed correctly
- [ ] Wazuh pipeline: HIDS alerts indexed in separate index
- [ ] All pipelines tested end-to-end with sample data
- [ ] Pipeline configs committed as source of truth to \`scripts/setup/configs/logstash/\`

## References
UIW CDP Proposal §4 Invariant 4: Single-Source-of-Truth"

new_issue \
  "Rebuild security monitoring dashboards in OpenSearch" \
  "PI-2: Platform Engineering" \
  "$SG,$TL" \
  "PI-2: Platform Engineering,type: task,priority: high" \
  "**Owner:** @${SG}, @${TL}
**Priority:** HIGH | **PI:** 2

## Description
Build the core security monitoring dashboards in OpenSearch Dashboards covering network traffic, host telemetry, and security alerts.

## Acceptance Criteria
- [ ] Network Overview dashboard: top talkers, protocol distribution, geo map
- [ ] Security Events dashboard: alert timeline, severity breakdown, MITRE ATT&CK heatmap placeholder
- [ ] Endpoint Activity dashboard: Wazuh agent events, integrity alerts
- [ ] Executive Summary dashboard: MTTD/MTTR metrics
- [ ] All dashboards exportable as NDJSON to \`configs/server/\`

## References
UIW CDP Proposal §3: Operational Security Visibility"

new_issue \
  "Update deployment documentation and runbooks" \
  "PI-2: Platform Engineering" \
  "$IP,$TL" \
  "PI-2: Platform Engineering,type: documentation,priority: high" \
  "**Owner:** @${IP} (lead), @${TL}
**Priority:** HIGH | **PI:** 2

## Description
Update all deployment documentation to reflect the OpenSearch stack. Retire all ELK-specific references and produce updated runbooks for the UIW Cyber Defence Platform.

## Acceptance Criteria
- [ ] \`docs/master_pipeline_guide.md\` updated for OpenSearch
- [ ] Docker Compose deployment guide updated
- [ ] New runbooks cover: start, stop, restart, validate, troubleshoot
- [ ] All ELK-era terminology updated to OpenSearch equivalents
- [ ] Docs reviewed and approved by @${TL}

## References
UIW CDP Implementation Plan — PI-2 Deliverables: Updated Deployment Documentation"

new_issue \
  "[Gate] PI-2 Exit Review: Telemetry visible, dashboards functional, alerting operational" \
  "PI-2: Platform Engineering" \
  "$TL,$SG" \
  "PI-2: Platform Engineering,type: gate-review,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 2 Exit Gate

## Gate Criteria (from UIW CDP Proposal §9)
This issue must be closed before PI-3 work begins.

### Hard Stop Criteria
- [ ] OpenSearch cluster actively indexes network and host telemetry from all sources
- [ ] OpenSearch Dashboards render cleanly without manual configuration steps
- [ ] Native alerting operational (at least one test alert fires correctly)
- [ ] All index pipelines verified end-to-end

### Disposition on Gate Failure
**Hard Stop.** Re-engineer deployment playbooks before initializing PI-3.

## References
UIW CDP Proposal §9: PI-2 Gate Criteria"

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-3: Detection Engineering Program (Milestone 4)"
echo "========================================================"

new_issue \
  "[Epic] PI-3: Detection Engineering Program" \
  "PI-3: Detection Engineering Program" \
  "$SG,$TL" \
  "PI-3: Detection Engineering,type: epic,priority: critical" \
  "## Epic: PI-3 Detection Engineering Program

**Lead:** @${SG} (Sterling Garnett)
**Support:** @${TL} (Tommy Lammers)
**Duration:** 4–5 Weeks

### Objectives
- Validate all existing Sigma rules against OpenSearch
- Build MITRE ATT&CK coverage matrix
- Create detection QA process
- Create rule lifecycle management workflow

### Deliverables
- [ ] Centralized Detection Repository
- [ ] ATT&CK Coverage Dashboard
- [ ] Detection Validation Framework

### Exit Criteria (Gate)
Detection coverage measurable. ATT&CK reporting operational. Sigma detections validated and represented in ATT&CK dashboard."

new_issue \
  "Validate all existing Sigma rules against OpenSearch" \
  "PI-3: Detection Engineering Program" \
  "$SG,$TL" \
  "PI-3: Detection Engineering,type: task,priority: critical" \
  "**Owner:** @${SG}, @${TL}
**Priority:** CRITICAL | **PI:** 3

## Description
Test every Sigma rule in the \`rules/\` directory against OpenSearch. Confirm each rule translates correctly, triggers on test data, and produces accurate alerts.

## Acceptance Criteria
- [ ] All rules in \`rules/\` directory tested against OpenSearch
- [ ] Each rule classified: Validated / Requires Fix / Deprecated
- [ ] False positive rate documented per rule
- [ ] Broken rules updated or flagged for removal
- [ ] Validated rule set committed back to \`rules/\`

## References
UIW CDP Proposal §3: Repeatable Detection Engineering"

new_issue \
  "Build MITRE ATT&CK coverage matrix for the lab environment" \
  "PI-3: Detection Engineering Program" \
  "$SG,$TL" \
  "PI-3: Detection Engineering,type: task,priority: critical" \
  "**Owner:** @${SG}, @${TL}
**Priority:** CRITICAL | **PI:** 3

## Description
Map all validated Sigma detections to their corresponding MITRE ATT&CK technique IDs. Build a coverage matrix showing which techniques are detected, partially detected, or undetected.

## Acceptance Criteria
- [ ] Every validated Sigma rule mapped to at least one ATT&CK Technique ID
- [ ] Coverage matrix produced showing: Detected / Partial / No Coverage per tactic
- [ ] Coverage matrix committed to \`docs/attack_matrix.md\`
- [ ] ATT&CK Coverage Dashboard created in OpenSearch Dashboards

## References
UIW CDP Implementation Plan — PI-3 Deliverables: ATT&CK Coverage Dashboard"

new_issue \
  "Create detection QA process and testing workflow" \
  "PI-3: Detection Engineering Program" \
  "$SG" \
  "PI-3: Detection Engineering,type: task,priority: high,type: documentation" \
  "**Owner:** @${SG}
**Priority:** HIGH | **PI:** 3

## Description
Define a formal Detection QA process that all new Sigma rules must pass before being merged into the detection repository.

## Acceptance Criteria
- [ ] QA checklist defined: syntax validation, test-data validation, ATT&CK mapping, false positive rate
- [ ] QA workflow documented in \`docs/\`
- [ ] Pull request template updated to include QA checklist
- [ ] At least 3 existing rules run through the new QA process as proof-of-concept

## References
UIW CDP Implementation Plan — PI-3 Objectives: Create detection QA process"

new_issue \
  "Create rule lifecycle management procedures" \
  "PI-3: Detection Engineering Program" \
  "$SG,$IP" \
  "PI-3: Detection Engineering,type: documentation,priority: high" \
  "**Owner:** @${SG}, @${IP}
**Priority:** HIGH | **PI:** 3

## Description
Define the full lifecycle for a Sigma detection rule: Creation → Review → Validation → Active → Deprecated → Retired. Document procedures for each stage.

## Acceptance Criteria
- [ ] Rule lifecycle stages defined with clear entry/exit criteria
- [ ] Version control strategy for rules documented (branching, tagging)
- [ ] Deprecation and retirement procedures written
- [ ] Lifecycle document committed to \`docs/\`

## References
UIW CDP Implementation Plan — PI-3 Objectives: Create rule lifecycle management"

new_issue \
  "Create Detection Validation Framework documentation" \
  "PI-3: Detection Engineering Program" \
  "$SG,$IP" \
  "PI-3: Detection Engineering,type: documentation,priority: high" \
  "**Owner:** @${SG}, @${IP}
**Priority:** HIGH | **PI:** 3

## Description
Produce the Detection Validation Framework — the authoritative document describing how detection rules are tested, validated, and coverage is measured in the UIW Cyber Defence Platform.

## Acceptance Criteria
- [ ] Framework covers: rule syntax validation, test data injection, alert verification, ATT&CK mapping, coverage reporting
- [ ] Framework references the QA checklist and lifecycle procedures
- [ ] Document committed to \`docs/\`
- [ ] Reviewed and approved by @${TL}

## References
UIW CDP Implementation Plan — PI-3 Deliverables: Detection Validation Framework"

new_issue \
  "[Gate] PI-3 Exit Review: Detection coverage measurable, ATT&CK reporting operational" \
  "PI-3: Detection Engineering Program" \
  "$TL,$SG" \
  "PI-3: Detection Engineering,type: gate-review,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 3 Exit Gate

## Gate Criteria (from UIW CDP Proposal §9)

### Hard Stop Criteria
- [ ] Sigma detections validated across the rule management framework
- [ ] ATT&CK coverage dashboard operational in OpenSearch Dashboards
- [ ] Detection coverage measurable (percentage of ATT&CK techniques covered)
- [ ] Synthetic attack playback triggers corresponding alerts within 60 seconds

### Disposition on Gate Failure
**Hard Stop.** Halt progression; fix indexing pipelines and rule syntax errors before proceeding to PI-4.

## References
UIW CDP Proposal §9: PI-3 Gate Criteria"

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-4: Adversary Validation (Milestone 5)"
echo "========================================================"

new_issue \
  "[Epic] PI-4: Adversary Validation" \
  "PI-4: Adversary Validation" \
  "$TL,$SG" \
  "PI-4: Adversary Validation,type: epic,priority: critical" \
  "## Epic: PI-4 Adversary Validation

**Lead:** @${TL} (Tommy Lammers)
**Support:** @${SG} (Sterling Garnett)
**Duration:** 4–6 Weeks

### Objectives
- Connect Adversary-in-a-Box emulation platform to SOC lab subnet
- Automate ATT&CK exercise playbooks
- Measure detection effectiveness per emulation run
- Generate automated coverage validation reports

### Deliverables
- [ ] Purple-Team Validation Environment
- [ ] Automated Coverage Reports
- [ ] Attack Replay Library

### Invariant: Written-Authorization Required
No offensive emulation tool or script shall be executed against UIW infrastructure without an active, signed Rules of Engagement (RoE) document.

### Exit Criteria (Gate)
Attacks produce measurable SOC outcomes. Synthetic playback triggers alerts within 60 seconds."

new_issue \
  "Connect Adversary-in-a-Box emulation platform to SOC lab subnet" \
  "PI-4: Adversary Validation" \
  "$TL,$SG" \
  "PI-4: Adversary Validation,type: task,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 4

## Description
Deploy and configure the Adversary-in-a-Box emulation platform within the UIW lab subnet. Ensure it can safely generate ATT&CK-mapped attack traffic that flows through the SOC telemetry pipeline.

## Acceptance Criteria
- [ ] Adversary-in-a-Box deployed in isolated emulation subnet
- [ ] Platform communicates with SOC monitoring stack
- [ ] Test attack generates visible telemetry in OpenSearch
- [ ] No unauthorized network paths outside emulation subnet
- [ ] RoE document signed before any execution (#RoE-issue)

## References
UIW CDP Proposal §5: Emulation Engine — Adversary-in-a-Box
UIW CDP Proposal §4 Invariant 5: Written-Authorization Invariant"

new_issue \
  "Author automated ATT&CK exercise playbooks" \
  "PI-4: Adversary Validation" \
  "$SG,$TL" \
  "PI-4: Adversary Validation,type: task,priority: high" \
  "**Owner:** @${SG}, @${TL}
**Priority:** HIGH | **PI:** 4

## Description
Write a library of automated attack playbooks mapped to MITRE ATT&CK techniques. Each playbook should safely replay a specific attack pattern and verify the corresponding SOC detection fires.

## Acceptance Criteria
- [ ] Minimum 5 playbooks covering: Reconnaissance, Initial Access, Execution, Lateral Movement, Exfiltration
- [ ] Each playbook linked to specific ATT&CK Technique ID(s)
- [ ] Each playbook includes: setup, execution, expected detection, teardown
- [ ] Playbooks committed to \`docs/playbooks/\`

## References
UIW CDP Implementation Plan — PI-4 Deliverables: Attack Replay Library"

new_issue \
  "Measure detection effectiveness per emulation run" \
  "PI-4: Adversary Validation" \
  "$SG,$TL" \
  "PI-4: Adversary Validation,type: task,priority: high" \
  "**Owner:** @${SG}, @${TL}
**Priority:** HIGH | **PI:** 4

## Description
Build a measurement workflow that tracks detection effectiveness for each adversary emulation run. Record: which attacks fired alerts, which were missed, and time-to-detect.

## Acceptance Criteria
- [ ] Measurement workflow defined and documented
- [ ] Per-run metrics captured: detected / missed / false-positive counts
- [ ] Time-to-detect measured against the 60-second gate criterion
- [ ] Results stored in \`evidence/\` directory per run
- [ ] Data feeds into ATT&CK Coverage Dashboard

## References
UIW CDP Implementation Plan — PI-4 Objectives: Measure detection effectiveness"

new_issue \
  "Generate automated coverage validation reports" \
  "PI-4: Adversary Validation" \
  "$SG,$IP" \
  "PI-4: Adversary Validation,type: task,priority: high" \
  "**Owner:** @${SG}, @${IP}
**Priority:** HIGH | **PI:** 4

## Description
Build automation that generates a coverage validation report after each adversary emulation cycle. The report should summarize: techniques tested, alerts fired, missed detections, and coverage percentage.

## Acceptance Criteria
- [ ] Report generation automated (script or scheduled)
- [ ] Report format: Markdown or PDF, includes ATT&CK coverage heatmap
- [ ] Reports stored in \`reports/\`
- [ ] Report template committed and documented

## References
UIW CDP Implementation Plan — PI-4 Deliverables: Automated Coverage Reports"

new_issue \
  "Create Rules of Engagement (RoE) document template" \
  "PI-4: Adversary Validation" \
  "$IP,$TL" \
  "PI-4: Adversary Validation,type: documentation,priority: critical" \
  "**Owner:** @${IP}, @${TL}
**Priority:** CRITICAL | **PI:** 4

## Description
Create the formal Rules of Engagement (RoE) template that must be signed before any offensive emulation tool is executed against UIW infrastructure.

## Acceptance Criteria
- [ ] RoE template includes: scope (specific subnet), time window, authorized techniques, stop-call authorities
- [ ] Template requires signatures from Lead Architect and faculty/lab supervisor
- [ ] RoE document template committed to \`governance/\`
- [ ] README references the RoE requirement

## References
UIW CDP Proposal §4 Invariant 5: Written-Authorization Invariant"

new_issue \
  "[Gate] PI-4 Exit Review: Attacks produce measurable SOC outcomes within 60 seconds" \
  "PI-4: Adversary Validation" \
  "$TL,$SG" \
  "PI-4: Adversary Validation,type: gate-review,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 4 Exit Gate

## Gate Criteria (from UIW CDP Proposal §9)

### Hard Stop Criteria
- [ ] Minimum 3 ATT&CK playbooks executed under signed RoE
- [ ] Each executed attack produces a corresponding alert in OpenSearch within 60 seconds
- [ ] Coverage report generated and reviewed
- [ ] No unauthorized network activity beyond emulation subnet
- [ ] Missed detections logged in Technical Debt Register

### Disposition on Gate Failure
**Hard Stop.** Telemetry or parsing failure must be remediated. Halt progression to PI-5 until gate passes.

## References
UIW CDP Proposal §9: PI-3/4/5 Gate Criteria"

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-5: Multi-Agent SOAR Core (Milestone 6)"
echo "========================================================"

new_issue \
  "[Epic] PI-5: Multi-Agent SOAR Core" \
  "PI-5: Multi-Agent SOAR Core" \
  "$TL,$SG" \
  "PI-5: Multi-Agent SOAR,type: epic,priority: critical" \
  "## Epic: PI-5 Multi-Agent SOAR Core

**Lead:** @${TL} (Tommy Lammers)
**Support:** @${SG} (Sterling Garnett)
**Duration:** 5–6 Weeks

### Objectives
- Deploy Ollama LLM infrastructure on university hardware
- Build Agent Communication Bus
- Deploy 4 specialized containerized Python agents
- Implement immutable audit logging

### The 4 Agents
1. **Response Agent (SOAR Core):** Webhook ingest, incident briefing, containment blueprints
2. **Threat Hunter Agent:** 15-minute scheduled OpenSearch behavioral queries
3. **CTI Agent:** VirusTotal / AlienVault OTX enrichment
4. **Compliance Agent:** MTTD/MTTR + NIST CSF executive summaries

### Invariants
- **Telemetry-Stays-on-Campus:** All telemetry processed by local Ollama. No raw data to external APIs.
- **Human-of-Record:** Zero autonomous containment authority. Every recommendation requires manual approval.
- **Containerized Execution Boundary:** All agents run in immutable containers.

### Exit Criteria (Gate)
Agents consume and process alerts. Human-in-the-loop validated. Exclusion-list containment queries blocked at wrapper layer."

new_issue \
  "Deploy and configure Ollama LLM infrastructure on university hardware" \
  "PI-5: Multi-Agent SOAR Core" \
  "$TL,$SG" \
  "PI-5: Multi-Agent SOAR,type: task,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 5

## Description
Deploy the Ollama LLM framework on UIW university hardware to serve as the local AI inference engine for all MAS agents. Configure appropriate models for security analysis tasks.

## Acceptance Criteria
- [ ] Ollama installed and running on university hardware (not cloud)
- [ ] At least one capable LLM model pulled and tested (e.g., Llama 3, Mistral)
- [ ] Ollama accessible by all MAS agent containers on the internal network
- [ ] No telemetry data transmitted to external APIs during processing
- [ ] Ollama endpoint documented in \`configs/\`

## References
UIW CDP Proposal §5: AI Execution Engine — Ollama Infrastructure
UIW CDP Proposal §4 Invariant 2: Telemetry-Stays-on-Campus"

new_issue \
  "Build Agent Communication Bus (Python)" \
  "PI-5: Multi-Agent SOAR Core" \
  "$TL,$SG" \
  "PI-5: Multi-Agent SOAR,type: task,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 5

## Description
Implement the internal Agent Communication Bus that allows the 4 MAS agents to communicate, pass alerts, and coordinate triage workflows.

## Acceptance Criteria
- [ ] Agent bus implemented as a Python service
- [ ] Supports message routing between all 4 agents
- [ ] Message schema defined and documented
- [ ] Bus runs as a containerized service in the MAS Docker Compose stack
- [ ] All inter-agent traffic stays on the internal container network

## References
UIW CDP Proposal §5: SOAR Framework — Custom Python MAS & Agent Bus
UIW CDP Proposal §6: The Multi-Agent System"

new_issue \
  "Develop Threat Hunter Agent — scheduled OpenSearch behavioral query (15-min cadence)" \
  "PI-5: Multi-Agent SOAR Core" \
  "$SG,$TL" \
  "PI-5: Multi-Agent SOAR,type: task,priority: high" \
  "**Owner:** @${SG}, @${TL}
**Priority:** HIGH | **PI:** 5

## Description
Build the Threat Hunter Agent: a containerized Python agent that executes scheduled OpenSearch queries every 15 minutes, hunting for behavioral anomalies including low-and-slow exfiltration, beaconing, and cross-segment policy violations.

## Acceptance Criteria
- [ ] Agent runs on 15-minute scheduled cadence
- [ ] Queries: beaconing detection, exfiltration pattern detection, cross-segment violations
- [ ] Findings promoted to analyst review queue (not auto-actioned)
- [ ] Agent containerized and included in Docker Compose stack
- [ ] All outputs logged to immutable audit log

## References
UIW CDP Proposal §6: Threat Hunter Agent"

new_issue \
  "Develop Compliance Agent — MTTD/MTTR + NIST CSF executive summary" \
  "PI-5: Multi-Agent SOAR Core" \
  "$SG,$IP" \
  "PI-5: Multi-Agent SOAR,type: task,priority: high" \
  "**Owner:** @${SG}, @${IP}
**Priority:** HIGH | **PI:** 5

## Description
Build the Compliance Agent: aggregates OpenSearch operational data into weekly executive summaries capturing MTTD, MTTR, and structural NIST CSF category mapping.

## Acceptance Criteria
- [ ] Agent produces weekly executive summary report
- [ ] Metrics captured: Mean Time to Detect (MTTD), Mean Time to Respond (MTTR)
- [ ] Report maps findings to NIST CSF categories
- [ ] Narrative generation uses pre-sanitized, anonymized data if external LLM fallback is used
- [ ] Reports stored in \`reports/\`

## References
UIW CDP Proposal §6: Compliance Agent"

new_issue \
  "Implement immutable audit logging for all agent actions" \
  "PI-5: Multi-Agent SOAR Core" \
  "$TL" \
  "PI-5: Multi-Agent SOAR,type: task,priority: critical" \
  "**Owner:** @${TL}
**Priority:** CRITICAL | **PI:** 5

## Description
Implement an immutable audit log that records every action taken by every MAS agent. The log must be append-only and tamper-evident.

## Acceptance Criteria
- [ ] Audit log captures: timestamp, agent ID, action type, input summary, output summary, analyst approval (Y/N)
- [ ] Log is append-only (no delete/update operations permitted)
- [ ] Log indexed in OpenSearch under dedicated index (e.g., \`uiw-agent-audit-*\`)
- [ ] Audit log dashboard created in OpenSearch Dashboards
- [ ] Log retention policy defined

## References
UIW CDP Implementation Plan — PI-5 Deliverables: Audit Logging
UIW CDP Proposal §4 Invariant 3: Human-of-Record"

new_issue \
  "Containerize full MAS stack with Docker Compose" \
  "PI-5: Multi-Agent SOAR Core" \
  "$TL,$SG" \
  "PI-5: Multi-Agent SOAR,type: task,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 5

## Description
Package the complete Multi-Agent System (all 4 agents + agent bus + Ollama) into a single Docker Compose deployment stack.

## Acceptance Criteria
- [ ] All 4 agents + agent bus containerized with Dockerfiles
- [ ] Single \`docker-compose.yml\` brings up full MAS stack
- [ ] Containers communicate only over internal \`mas-net\` Docker network
- [ ] Environment variables used for all secrets and config (no hardcoded credentials)
- [ ] Docker Compose file committed to \`scripts/setup/\`
- [ ] Deployment tested from cold start

## References
UIW CDP Proposal §4 Invariant 1: Containerized Execution Boundary"

new_issue \
  "[Gate] PI-5 Exit Review: Agents process alerts, human-in-the-loop validated" \
  "PI-5: Multi-Agent SOAR Core" \
  "$TL,$SG" \
  "PI-5: Multi-Agent SOAR,type: gate-review,priority: critical" \
  "**Owner:** @${TL}, @${SG}
**Priority:** CRITICAL | **PI:** 5 Exit Gate

## Gate Criteria (from UIW CDP Proposal §9)

### Hard Stop Criteria
- [ ] All 4 agents consume and process alerts from OpenSearch
- [ ] Webhook alerts generate accurate incident briefings within 30 seconds
- [ ] Human-in-the-loop approval required before any containment action executes
- [ ] Exclusion-list containment queries blocked at the wrapper layer
- [ ] Immutable audit log captures all agent actions
- [ ] No telemetry data transmitted outside university hardware

### Disposition on Gate Failure
**Hard Stop.** Immediately suspend external fallback or local routing anomalies. Fix and re-test.

## References
UIW CDP Proposal §9: PI-3/4/5 Gate Criteria"

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-6: Student Analyst Operations (Milestone 7)"
echo "========================================================"

new_issue \
  "[Epic] PI-6: Student Analyst Operations" \
  "PI-6: Student Analyst Operations" \
  "$IP,$TL" \
  "PI-6: Student Analyst Ops,type: epic,priority: high" \
  "## Epic: PI-6 Student Analyst Operations

**Lead:** @${IP} (Ishmael Pendleton — Master Documentation Owner)
**Support:** @${TL} (Tommy Lammers)
**Duration:** 3–4 Weeks

### Objectives
- Create workflows for Student Observer persona
- Create workflows for Student Analyst persona
- Create workflows for Student Threat Hunter persona

### Deliverables
- [ ] Student Analyst Handbook
- [ ] SOC Operations Guide
- [ ] Training Exercises (3 tiers)
- [ ] Operational Procedures

### Exit Criteria (Gate)
New students can operate the platform independently after onboarding."

new_issue \
  "Write Student Analyst Handbook (Observer, Analyst, Threat Hunter personas)" \
  "PI-6: Student Analyst Operations" \
  "$IP,$TL" \
  "PI-6: Student Analyst Ops,type: documentation,priority: critical" \
  "**Owner:** @${IP} (lead), @${TL}
**Priority:** CRITICAL | **PI:** 6

## Description
Write the Student Analyst Handbook covering all three operational personas that student analysts may hold within the UIW Cyber Defence Platform SOC.

## Personas
1. **Student Observer** — Read-only access, dashboard review, alert triage exposure
2. **Student Analyst** — Alert investigation, query authoring, escalation procedures
3. **Student Threat Hunter** — Proactive hunt queries, anomaly investigation, detection gap reporting

## Acceptance Criteria
- [ ] Handbook covers all 3 personas with role-specific procedures
- [ ] Each persona section includes: responsibilities, tools, escalation paths, example workflows
- [ ] Handbook committed to \`docs/\`
- [ ] Reviewed by at least one student analyst (fresh-eyes review)

## References
UIW CDP Implementation Plan — PI-6 Deliverables: Student Analyst Handbook"

new_issue \
  "Write SOC Operations Guide" \
  "PI-6: Student Analyst Operations" \
  "$IP,$SG" \
  "PI-6: Student Analyst Ops,type: documentation,priority: high" \
  "**Owner:** @${IP} (lead), @${SG}
**Priority:** HIGH | **PI:** 6

## Description
Write the SOC Operations Guide — the day-to-day operational reference for running the UIW Cyber Defence Platform SOC. Covers platform startup, shutdown, monitoring, alert handling, and escalation.

## Acceptance Criteria
- [ ] Guide covers: platform startup checklist, health verification, alert triage workflow, escalation matrix, shutdown procedure
- [ ] Includes quick-reference command cheat sheet
- [ ] References all relevant SOPs
- [ ] Guide committed to \`docs/\`

## References
UIW CDP Implementation Plan — PI-6 Deliverables: SOC Operations Guide"

new_issue \
  "Develop tiered Training Exercises (3 tiers: Observer, Analyst, Threat Hunter)" \
  "PI-6: Student Analyst Operations" \
  "$SG,$IP" \
  "PI-6: Student Analyst Ops,type: task,priority: high" \
  "**Owner:** @${SG}, @${IP}
**Priority:** HIGH | **PI:** 6

## Description
Develop a set of hands-on training exercises at three difficulty tiers aligned to the three student analyst personas.

## Acceptance Criteria
- [ ] Tier 1 (Observer): Dashboard reading, alert identification, basic KQL queries
- [ ] Tier 2 (Analyst): Alert investigation, OpenSearch query authoring, escalation decision
- [ ] Tier 3 (Threat Hunter): Proactive behavioral hunt, detection gap identification, new rule proposal
- [ ] Each exercise includes: scenario, step-by-step instructions, expected outcome, debrief questions
- [ ] Exercises committed to \`docs/\`

## References
UIW CDP Implementation Plan — PI-6 Deliverables: Training Exercises"

new_issue \
  "Write Operational Procedures for common SOC response actions" \
  "PI-6: Student Analyst Operations" \
  "$IP,$SG" \
  "PI-6: Student Analyst Ops,type: documentation,priority: high" \
  "**Owner:** @${IP} (lead), @${SG}
**Priority:** HIGH | **PI:** 6

## Description
Document standard operational procedures (SOPs) for the most common response actions a Student Analyst will take in the UIW Cyber Defence Platform.

## Acceptance Criteria
- [ ] SOP-001: Pipeline Operations (update existing)
- [ ] SOP-002: Alert Triage and Escalation
- [ ] SOP-003: Running an Adversary Emulation Exercise
- [ ] SOP-004: Requesting AI Agent Analysis
- [ ] SOP-005: Executing a Containment Blueprint
- [ ] All SOPs committed to \`docs/\`

## References
UIW CDP Implementation Plan — PI-6 Deliverables: Operational Procedures"

new_issue \
  "[Gate] PI-6 Exit Review: New students operate platform independently" \
  "PI-6: Student Analyst Operations" \
  "$TL,$IP" \
  "PI-6: Student Analyst Ops,type: gate-review,priority: high" \
  "**Owner:** @${TL}, @${IP}
**Priority:** HIGH | **PI:** 6 Exit Gate

## Gate Criteria (from UIW CDP Proposal §9)

### Extension Criteria
- [ ] Onboarding evaluation: newly recruited student analysts can independently interpret alerts and dashboards
- [ ] Student Analyst Handbook reviewed and approved
- [ ] All 3 training exercise tiers tested with at least one student
- [ ] SOC Operations Guide verified against the live platform

### Disposition on Gate Failure
**Gate Extension.** Additional instructional runbooks and guidelines must be authored before PI-7.

## References
UIW CDP Proposal §9: PI-6 Gate Criteria"

# ===========================================================================
echo ""
echo "========================================================"
echo "  PI-7: Capstone Demonstration (Milestone 8)"
echo "========================================================"

new_issue \
  "[Epic] PI-7: Capstone Demonstration" \
  "PI-7: Capstone Demonstration" \
  "$TL,$SG,$IP" \
  "PI-7: Capstone Demo,type: epic,priority: critical" \
  "## Epic: PI-7 Capstone Demonstration

**All Hands: @${TL}, @${SG}, @${IP}**
**Duration:** 1 Week

### Live Scenario Sequence
1. Adversary-in-a-Box generates attack
2. Telemetry visible in OpenSearch
3. Validated Sigma detection fires
4. AI agent generates enriched incident briefing
5. Student Analyst investigates via OpenSearch Dashboards
6. Student Analyst executes informed manual mitigation

### Deliverables
- [ ] Capstone Presentation
- [ ] Technical Documentation Package
- [ ] Final Architecture Diagrams
- [ ] Deployment Guide

### Exit Criteria (Gate)
Flawless end-to-end workflow: attack → OpenSearch alert → Ollama analysis → human mitigation. No component failures.

### Definition of Success
The UIW Cyber Defence Platform succeeds when a Student Analyst can:
1. Observe an attack generated by Adversary-in-a-Box
2. See telemetry within OpenSearch
3. Observe a validated detection
4. Receive AI-assisted analysis
5. Investigate the event
6. Execute an informed response"

new_issue \
  "Prepare Capstone Presentation deck" \
  "PI-7: Capstone Demonstration" \
  "$TL,$SG,$IP" \
  "PI-7: Capstone Demo,type: task,priority: critical" \
  "**Owner:** @${TL}, @${SG}, @${IP}
**Priority:** CRITICAL | **PI:** 7

## Description
Prepare the formal Capstone Presentation demonstrating the UIW Cyber Defence Platform end-to-end. Must include live demonstration sequence.

## Acceptance Criteria
- [ ] Presentation covers: platform architecture, 7-PI journey, live demo walkthrough, Definition of Success outcome
- [ ] Live demo sequence scripted and rehearsed minimum 2x
- [ ] Fallback slides prepared in case of technical failure
- [ ] Presentation committed to \`docs/presentation_slides.md\` or equivalent

## References
UIW CDP Implementation Plan — PI-7 Deliverables: Capstone Presentation"

new_issue \
  "Finalize Technical Documentation package" \
  "PI-7: Capstone Demonstration" \
  "$IP,$TL" \
  "PI-7: Capstone Demo,type: documentation,priority: critical" \
  "**Owner:** @${IP} (lead), @${TL}
**Priority:** CRITICAL | **PI:** 7

## Description
Assemble and finalize the complete Technical Documentation package for the UIW Cyber Defence Platform. This is the handoff artifact for future Student Analysts.

## Acceptance Criteria
- [ ] All PI deliverable documents reviewed and finalized
- [ ] Technical Debt Register shows resolved items or accepted risks
- [ ] Deployment Guide validated against a clean-install test
- [ ] Documentation package organized and linked from README
- [ ] All docs committed to \`docs/\`

## References
UIW CDP Implementation Plan — PI-7 Deliverables: Technical Documentation"

new_issue \
  "Produce final Architecture Diagrams" \
  "PI-7: Capstone Demonstration" \
  "$TL,$IP" \
  "PI-7: Capstone Demo,type: documentation,priority: high" \
  "**Owner:** @${TL}, @${IP}
**Priority:** HIGH | **PI:** 7

## Description
Produce final, publication-quality architecture diagrams for the UIW Cyber Defence Platform covering: overall system architecture, MAS agent topology, network topology, and data flow.

## Acceptance Criteria
- [ ] Overall platform architecture diagram (all components and data flows)
- [ ] MAS agent topology diagram (4 agents + bus + Ollama)
- [ ] Network topology diagram (VLANs, sensor placement, SPAN ports)
- [ ] Data flow diagram (telemetry source → OpenSearch → agent → analyst)
- [ ] All diagrams committed to \`docs/\` in PNG and source format

## References
UIW CDP Implementation Plan — PI-7 Deliverables: Architecture Diagrams"

new_issue \
  "[Gate] PI-7 Exit Review: End-to-end demo — attack → alert → AI analysis → analyst response" \
  "PI-7: Capstone Demonstration" \
  "$TL,$SG,$IP" \
  "PI-7: Capstone Demo,type: gate-review,priority: critical" \
  "**Owner:** @${TL}, @${SG}, @${IP}
**Priority:** CRITICAL | **PI:** 7 Exit Gate — Definition of Success

## Gate Criteria (from UIW CDP Proposal §9)

### The 6-Step Definition of Success
- [ ] 1. Student Analyst observes an unannounced attack generated by Adversary-in-a-Box
- [ ] 2. Raw network and host telemetry visible in OpenSearch within expected time
- [ ] 3. Validated, non-duplicated alert generated by the Sigma Detection Engine
- [ ] 4. Enriched plain-English incident briefing compiled by the Multi-Agent SOAR framework
- [ ] 5. Historical event context investigated using OpenSearch Dashboards
- [ ] 6. Prescriptive manual mitigation blueprint executed by the Student Analyst

### Disposition on Gate Failure
**Redo.** Re-evaluate system components, refine playbook automation, and re-test live scenario.

### Platform Success Statement
At this juncture, the UIW Cyber Defence Platform has fully accomplished its capstone mission.

## References
UIW CDP Proposal §11: Definition of Success
UIW CDP Proposal §9: PI-7 Gate Criteria"

echo ""
echo "========================================================"
echo "  All PI issues created successfully!"
echo "========================================================"
