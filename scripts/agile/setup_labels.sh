#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — GitHub Label Setup
# Repo: voltron-1/UIW-CDPv2
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-CDPv2"

create_or_update_label() {
  local name="$1"
  local color="$2"
  local desc="$3"
  local encoded
  encoded=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "$name")

  if gh api "repos/${REPO}/labels/${encoded}" > /dev/null 2>&1; then
    gh api "repos/${REPO}/labels/${encoded}" -X PATCH \
      -f color="$color" \
      -f description="$desc" > /dev/null
    echo "  [updated] $name"
  else
    gh api "repos/${REPO}/labels" -X POST \
      -f name="$name" \
      -f color="$color" \
      -f description="$desc" > /dev/null
    echo "  [created] $name"
  fi
}

echo ""
echo "=== PI Epic Labels ==="
create_or_update_label "PI-1: Foundation Assessment"  "B60205" "PI-1: Audit, gap analysis, infrastructure hardening baseline"
create_or_update_label "PI-2: Platform Engineering"   "0E8A16" "PI-2: OpenSearch migration, pipelines, dashboards"
create_or_update_label "PI-3: Detection Engineering"  "1D76DB" "PI-3: Sigma validation, ATT&CK mapping, detection QA"
create_or_update_label "PI-4: Adversary Validation"   "D93F0B" "PI-4: Adversary-in-a-Box, purple team, coverage reports"
create_or_update_label "PI-5: Multi-Agent SOAR"       "6F42C1" "PI-5: Ollama, MAS agents, agent bus, audit logging"
create_or_update_label "PI-6: Student Analyst Ops"    "0075CA" "PI-6: Handbook, SOC ops guide, training exercises"
create_or_update_label "PI-7: Capstone Demo"          "C5DEF5" "PI-7: End-to-end live demo and final documentation package"

echo ""
echo "=== Type Labels ==="
create_or_update_label "type: epic"          "F9D0C4" "Parent epic issue grouping a full PI"
create_or_update_label "type: user-story"    "BFD4F2" "User-facing capability or requirement"
create_or_update_label "type: task"          "D4C5F9" "Discrete implementation task"
create_or_update_label "type: gate-review"   "FEF2C0" "PI exit gate review checklist"
create_or_update_label "type: documentation" "006B75" "Documentation or runbook task"

echo ""
echo "=== Priority Labels ==="
create_or_update_label "priority: critical" "B60205" "Blocker — must complete before PI can progress"
create_or_update_label "priority: high"     "E99695" "Required for PI completion"
create_or_update_label "priority: medium"   "F9D0C4" "Important but not blocking"
create_or_update_label "priority: low"      "FEF2C0" "Nice to have"

echo ""
echo "=== All labels complete ==="
