#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — Strategic Framework Alignment: Label Setup
# Repo: voltron-1/UIW-Cyber-Defence-Platform
#
# Adds the workstream + type labels used by the Framework Alignment milestone
# (NIST CSF 2.0 / ISO 27001 / SOC-CMM / MITRE ATT&CK).
# Mirrors scripts/agile/setup_labels.sh conventions (create-or-update).
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-Cyber-Defence-Platform"

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
echo "=== Framework Workstream Labels ==="
create_or_update_label "FW-A: Governance (CSF/ISO)" "5319E7" "WS-A: NIST CSF 2.0 profile, ISO 27001 SoA, policies, risk register"
create_or_update_label "FW-B: SOC-CMM Maturity"     "0E8A16" "WS-B: SOC-CMM baseline assessment, roles/RACI, metrics, cadence"
create_or_update_label "FW-C: ATT&CK Coverage"      "1D76DB" "WS-C: Navigator layer, coverage scorecard, detection lifecycle/QA"
create_or_update_label "FW-D: Traceability"         "B60205" "WS-D: CSF<->ISO<->SOC-CMM<->ATT&CK master matrix and CI enforcement"

echo ""
echo "=== Framework Type Label ==="
create_or_update_label "type: framework" "C2E0C6" "Strategic framework alignment (governance / maturity / coverage)"

echo ""
echo "=== Framework labels complete ==="
