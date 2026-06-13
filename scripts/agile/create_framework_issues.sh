#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — Strategic Framework Alignment: Issue Creation
# Repo: voltron-1/UIW-Cyber-Defence-Platform
#
# Creates 4 workstream epics + 15 tasks for the Framework Alignment milestone
# (NIST CSF 2.0 / ISO 27001 / SOC-CMM / MITRE ATT&CK), adds each to the
# "UIW Cyber Defence Platform" project board (#6), and sets Status = Backlog.
#
# Prerequisites (run first):
#   ./setup_framework_labels.sh
#   ./setup_framework_milestone.sh
#
# Mirrors scripts/agile/create_pi_issues.sh conventions.
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-Cyber-Defence-Platform"
OWNER="voltron-1"
PROJECT_NUMBER="6"                                   # "UIW Cyber Defence Platform"
STATUS_FIELD_ID="PVTSSF_lAHODKiy2s4BYh4fzhTnH-c"     # Status single-select field
BACKLOG_OPTION_ID="f75ad846"                          # Status -> Backlog
MILESTONE="Framework Alignment: NIST CSF 2.0 / ISO 27001 / SOC-CMM / ATT&CK"

TL="voltron-1"       # Tommy Lammers — Lead Architect
SG="sterlinggarnett" # Sterling Garnett — Security Analyst
IP="cryptgrphy"      # Ishmael Pendleton — Network Engineer / Documentation

PROJECT_ID=$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json --jq '.id')

# new_issue <title> <assignees> <labels> <body>
# Creates the issue, adds it to the board, and sets Status = Backlog.
new_issue() {
  local title="$1" assignees="$2" labels="$3" body="$4"
  local url item_id

  url=$(gh issue create -R "$REPO" \
    -t "$title" \
    -b "$body" \
    -m "$MILESTONE" \
    -l "$labels" \
    -a "$assignees")
  echo "  [created] $url"

  item_id=$(gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$url" --format json --jq '.id')
  gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" \
    --field-id "$STATUS_FIELD_ID" --single-select-option-id "$BACKLOG_OPTION_ID" > /dev/null
  echo "            -> board: Backlog"
}

# ===========================================================================
echo ""
echo "========================================================"
echo "  WS-A: Governance & Compliance (NIST CSF 2.0 / ISO 27001)"
echo "========================================================"

new_issue \
  "[Epic] FW-A: Governance & Compliance Layer (NIST CSF 2.0 / ISO 27001)" \
  "$IP,$TL" \
  "FW-A: Governance (CSF/ISO),type: epic,type: framework,priority: critical" \
  "## Epic: Governance & Compliance Layer

**Lead:** @${IP} · **Support:** @${TL} · **Supports PI:** PI-1 (Foundation)

The top of the Strategic Framework Architecture. Establishes the governance
artifacts that every detection, SOP, and script traces upward to.

### Deliverables
- [ ] Governance pack: policies, risk register, RoE register, ISO 27001 SoA
- [ ] NIST CSF 2.0 Current/Target Profile across all **6** functions (incl. Govern)
- [ ] ISO 27001:2022 Annex A control mapping
- [ ] Compliance evidence automation (rule/SOP metadata -> CISO report)

### Reference
docs/internal documents/UIW_Strategic_Framework_Alignment_Plan.md — WS-A"

new_issue \
  "FW-A1: Create governance pack (policies, risk register, RoE register, SoA)" \
  "$IP,$TL" \
  "FW-A: Governance (CSF/ISO),type: documentation,type: framework,priority: critical" \
  "**Owner:** @${IP}, @${TL} | **WS:** A1

## Description
Stand up the \`governance/\` documentation pack — short, lab-appropriate
artifacts (not enterprise boilerplate) that define what good looks like.

## Acceptance Criteria
- [ ] \`governance/policies/\` — Information Security, Acceptable Use, Logging &
      Monitoring, Incident Response, Access Control, Change Management (1–2 pp each)
- [ ] \`governance/risk-register.md\` — risk ID, likelihood, impact, owner,
      treatment, residual risk, linked CSF/ISO control
- [ ] \`governance/roe-register.md\` — index of signed Rules of Engagement (enforces
      the Written-Authorization invariant)
- [ ] \`governance/statement-of-applicability.md\` — ISO 27001:2022 SoA skeleton

## Reference
Strategic Framework Alignment Plan — WS-A1"

new_issue \
  "FW-A2: Adopt NIST CSF 2.0 — add Govern function + Current/Target Profile" \
  "$TL,$IP" \
  "FW-A: Governance (CSF/ISO),type: task,type: framework,priority: critical" \
  "**Owner:** @${TL}, @${IP} | **WS:** A2

## Description
Upgrade from the legacy 5-function model to CSF 2.0 (6 functions). The repo
currently omits **Govern (GV)**.

## Acceptance Criteria
- [ ] \`governance/nist-csf-2.0-profile.md\` — Current vs. Target Profile across
      GV, ID, PR, DE, RS, RC with per-Category tier (1–4) + gap notes
- [ ] \`scripts/setup/ai_agent/weekly_ciso_report.py\`: add \"Govern\" to
      \`NIST_FUNCTIONS\` and handle \`GV:*\` tags
- [ ] CISO report renders all 6 functions (verified on sample data)

## Reference
Strategic Framework Alignment Plan — WS-A2"

new_issue \
  "FW-A3: ISO 27001:2022 Annex A control mapping" \
  "$IP,$TL" \
  "FW-A: Governance (CSF/ISO),type: documentation,type: framework,priority: high" \
  "**Owner:** @${IP}, @${TL} | **WS:** A3

## Description
Map the 93 ISO 27001:2022 Annex A controls (Organizational, People, Physical,
Technological) to repo evidence and CSF subcategories.

## Acceptance Criteria
- [ ] \`governance/iso27001-annexA-mapping.md\` lists every Annex A control
- [ ] Each control marked Implemented / Partial / N-A-for-lab with justification
- [ ] Each control cross-references its CSF 2.0 subcategory and evidence link

## Reference
Strategic Framework Alignment Plan — WS-A3"

new_issue \
  "FW-A4: Compliance evidence automation (rule/SOP metadata -> CISO report)" \
  "$SG,$TL" \
  "FW-A: Governance (CSF/ISO),type: task,type: framework,priority: high" \
  "**Owner:** @${SG}, @${TL} | **WS:** A4

## Description
Drive compliance coverage from artifact metadata instead of hardcoded demo data.

## Acceptance Criteria
- [ ] Every Sigma rule + SOP carries \`nist_csf:\` and \`iso27001:\` metadata fields
- [ ] \`weekly_ciso_report.py\` aggregates coverage per CSF function from that metadata
- [ ] Report shows a real per-function coverage figure (not the demo fallback)

## Reference
Strategic Framework Alignment Plan — WS-A4"

# ===========================================================================
echo ""
echo "========================================================"
echo "  WS-B: SOC-CMM Operational Maturity"
echo "========================================================"

new_issue \
  "[Epic] FW-B: SOC-CMM Operational Maturity (People & Process)" \
  "$TL,$IP" \
  "FW-B: SOC-CMM Maturity,type: epic,type: framework,priority: high" \
  "## Epic: SOC-CMM Operational Maturity

**Lead:** @${TL} · **Support:** @${IP} · **Supports PI:** PI-1, PI-6

Establishes the maturity baseline the program measurably improves against,
across the five SOC-CMM domains: Business, People, Process, Technology, Services.

### Deliverables
- [ ] Scored SOC-CMM baseline assessment (dated snapshot)
- [ ] Roles + RACI + numbered SOP index
- [ ] Operational metrics catalog + dashboard (MTTD/MTTR/coverage/FP)
- [ ] Improvement backlog + per-PI re-assessment cadence

### Reference
Strategic Framework Alignment Plan — WS-B"

new_issue \
  "FW-B1: SOC-CMM baseline assessment (5 domains, scored)" \
  "$TL,$IP" \
  "FW-B: SOC-CMM Maturity,type: documentation,type: framework,priority: critical" \
  "**Owner:** @${TL}, @${IP} | **WS:** B1

## Description
Score the SOC against the SOC-CMM model and capture a dated baseline.

## Acceptance Criteria
- [ ] \`governance/soc-cmm/assessment.md\` (or .csv) scores Business, People,
      Process, Technology, Services (+ Services sub-domains: Monitoring, IR,
      Threat Intel, Threat Hunting, Use-Case Mgmt)
- [ ] Each element scored 0–5 on the SOC-CMM maturity/capability scale
- [ ] Dated baseline snapshot committed

## Reference
Strategic Framework Alignment Plan — WS-B1"

new_issue \
  "FW-B2: Roles, RACI, and numbered SOP index" \
  "$IP,$SG" \
  "FW-B: SOC-CMM Maturity,type: documentation,type: framework,priority: high" \
  "**Owner:** @${IP}, @${SG} | **WS:** B2

## Description
Document the People/Process domains: who does what, and the SOP catalogue.

## Acceptance Criteria
- [ ] \`docs/operations/roles-and-raci.md\` maps Student Observer/Analyst/Threat
      Hunter to responsibilities and SOC-CMM People elements
- [ ] Existing SOPs (SOP-001, SOP-022) promoted into a numbered SOP index
- [ ] Process gaps filled: triage, escalation, on/offboarding, detection
      change-management, post-incident review

## Reference
Strategic Framework Alignment Plan — WS-B2"

new_issue \
  "FW-B3: Operational metrics catalog + dashboard" \
  "$SG,$TL" \
  "FW-B: SOC-CMM Maturity,type: task,type: framework,priority: high" \
  "**Owner:** @${SG}, @${TL} | **WS:** B3

## Description
Define and instrument SOC-CMM-aligned KPIs.

## Acceptance Criteria
- [ ] \`docs/operations/metrics-catalog.md\` — each metric: definition, OpenSearch
      source index, target, owner (MTTD, MTTR, coverage %, FP rate, backlog burn-down)
- [ ] Metrics surfaced in a dashboard NDJSON under \`configs/server/\`

## Reference
Strategic Framework Alignment Plan — WS-B3"

new_issue \
  "FW-B4: Improvement backlog + re-assessment cadence" \
  "$TL,$IP" \
  "FW-B: SOC-CMM Maturity,type: task,type: framework,priority: medium" \
  "**Owner:** @${TL}, @${IP} | **WS:** B4

## Description
Turn maturity gaps into a tracked, recurring improvement loop.

## Acceptance Criteria
- [ ] \`governance/soc-cmm/improvement-backlog.md\` — gaps from B1 prioritized
- [ ] Re-assessment cadence defined (e.g., once per PI) so maturity trend is tracked
- [ ] Top backlog items raised as GitHub issues (reuse scripts/agile tooling)

## Reference
Strategic Framework Alignment Plan — WS-B4"

# ===========================================================================
echo ""
echo "========================================================"
echo "  WS-C: MITRE ATT&CK Detection Engineering"
echo "========================================================"

new_issue \
  "[Epic] FW-C: MITRE ATT&CK Detection Engineering (Coverage Scoring)" \
  "$SG,$TL" \
  "FW-C: ATT&CK Coverage,type: epic,type: framework,priority: critical" \
  "## Epic: MITRE ATT&CK Detection Engineering

**Lead:** @${SG} · **Support:** @${TL} · **Supports PI:** PI-3, PI-4

Mature the flat coverage table into a generated, telemetry-aware, lifecycle-
managed coverage program.

### Deliverables
- [ ] ATT&CK Navigator layer generated from rules/sigma/
- [ ] Telemetry-aware coverage scorecard
- [ ] Detection lifecycle + QA + CI gate
- [ ] Threat-hunt hypotheses mapped to ATT&CK white space

### Reference
Strategic Framework Alignment Plan — WS-C"

new_issue \
  "FW-C1: Generate ATT&CK Navigator layer from Sigma rules" \
  "$SG,$TL" \
  "FW-C: ATT&CK Coverage,type: task,type: framework,priority: critical" \
  "**Owner:** @${SG}, @${TL} | **WS:** C1

## Description
Produce a machine-readable Navigator layer so coverage is rendered, not just listed.

## Acceptance Criteria
- [ ] \`scripts/setup/generate_attack_layer.py\` builds the layer from rules/sigma/ tags
- [ ] \`rules/attack/navigator-layer.json\` scores cells by detection count
- [ ] Importing the JSON into ATT&CK Navigator highlights the current techniques
- [ ] \`docs/attack_matrix.md\` regenerated from the same source (no drift)

## Reference
Strategic Framework Alignment Plan — WS-C1"

new_issue \
  "FW-C2: Detection coverage scorecard (telemetry-aware)" \
  "$SG,$TL" \
  "FW-C: ATT&CK Coverage,type: documentation,type: framework,priority: high" \
  "**Owner:** @${SG}, @${TL} | **WS:** C2

## Description
Distinguish 'tagged' from 'actually detectable' — a rule with no telemetry is no coverage.

## Acceptance Criteria
- [ ] \`docs/detections/coverage-scorecard.md\` — per technique: rule(s), required
      data source, telemetry-available (Y/N), confidence (low/med/high),
      tested-by (link to tests/anomaly_simulation/), last-validated date

## Reference
Strategic Framework Alignment Plan — WS-C2"

new_issue \
  "FW-C3: Detection lifecycle + QA + CI gate" \
  "$SG,$TL" \
  "FW-C: ATT&CK Coverage,type: task,type: framework,priority: high" \
  "**Owner:** @${SG}, @${TL} | **WS:** C3

## Description
Formalize how a detection moves Draft -> Test -> Production -> Deprecated, and enforce it.

## Acceptance Criteria
- [ ] \`docs/detections/detection-lifecycle.md\` — states, QA checklist, AiB validation linkage
- [ ] Each Sigma rule's validation links to a sim in tests/anomaly_simulation/
- [ ] CI job (extend .github/workflows/) lints Sigma rules; fails on missing
      \`attack.*\` tags or missing \`nist_csf:\` metadata

## Reference
Strategic Framework Alignment Plan — WS-C3"

new_issue \
  "FW-C4: Threat-hunt hypotheses mapped to ATT&CK white space" \
  "$SG,$IP" \
  "FW-C: ATT&CK Coverage,type: documentation,type: framework,priority: medium" \
  "**Owner:** @${SG}, @${IP} | **WS:** C4

## Description
Connect the Threat Hunter Agent to ATT&CK gaps where no automated rule exists.

## Acceptance Criteria
- [ ] \`docs/detections/hunt-hypotheses.md\` indexes hunt hypotheses by ATT&CK technique
- [ ] Hypotheses target the uncovered cells on the Navigator layer

## Reference
Strategic Framework Alignment Plan — WS-C4"

# ===========================================================================
echo ""
echo "========================================================"
echo "  WS-D: Cross-Framework Traceability & Enforcement"
echo "========================================================"

new_issue \
  "[Epic] FW-D: Cross-Framework Traceability & Enforcement" \
  "$TL,$SG" \
  "FW-D: Traceability,type: epic,type: framework,priority: high" \
  "## Epic: Cross-Framework Traceability

**Lead:** @${TL} · **Support:** @${SG} · **Supports PI:** PI-7

The glue that makes the three layers one system: CSF <-> ISO <-> SOC-CMM <->
ATT&CK <-> repo artifact <-> evidence.

### Deliverables
- [ ] Master traceability matrix (generated)
- [ ] Standard metadata schema + builder script
- [ ] Repo conventions + CI gate + 6th architectural invariant

### Reference
Strategic Framework Alignment Plan — WS-D"

new_issue \
  "FW-D1: Master traceability matrix (CSF <-> ISO <-> SOC-CMM <-> ATT&CK)" \
  "$TL,$SG" \
  "FW-D: Traceability,type: documentation,type: framework,priority: high" \
  "**Owner:** @${TL}, @${SG} | **WS:** D1

## Description
One artifact a reviewer reads to confirm the architecture holds end to end.

## Acceptance Criteria
- [ ] \`governance/traceability-matrix.md\` (or generated .csv): one row per control
      objective linking CSF 2.0 subcategory <-> ISO Annex A control <-> SOC-CMM
      element <-> ATT&CK technique(s) <-> repo artifact <-> evidence

## Reference
Strategic Framework Alignment Plan — WS-D1"

new_issue \
  "FW-D2: Metadata schema + traceability builder script" \
  "$TL,$SG" \
  "FW-D: Traceability,type: task,type: framework,priority: high" \
  "**Owner:** @${TL}, @${SG} | **WS:** D2

## Description
Make the matrix generated, not hand-maintained.

## Acceptance Criteria
- [ ] Standard front-matter schema defined: \`nist_csf\`, \`iso27001\`, \`soc_cmm\`, \`attack\`
- [ ] Schema applied to Sigma rules and SOPs
- [ ] \`scripts/setup/build_traceability.py\` assembles D1 from that metadata

## Reference
Strategic Framework Alignment Plan — WS-D2"

new_issue \
  "FW-D3: Repo conventions + CI gate + 6th architectural invariant" \
  "$TL,$IP" \
  "FW-D: Traceability,type: task,type: framework,priority: medium" \
  "**Owner:** @${TL}, @${IP} | **WS:** D3

## Description
Lock the standard in so it cannot silently regress.

## Acceptance Criteria
- [ ] README 'Architectural Invariants' gains a 6th: Framework-Traceability-Required
- [ ] CI job validates framework metadata presence on detections/SOPs and
      regenerates the traceability matrix on PR

## Reference
Strategic Framework Alignment Plan — WS-D3"

echo ""
echo "========================================================"
echo "  All Framework Alignment issues created and boarded!"
echo "========================================================"
