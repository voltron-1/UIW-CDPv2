#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — Strategic Framework Alignment: Milestone Setup
# Repo: voltron-1/UIW-Cyber-Defence-Platform
#
# Creates the cross-cutting "Framework Alignment" milestone that tracks the
# four workstreams (WS-A..WS-D) defined in
#   docs/internal documents/UIW_Strategic_Framework_Alignment_Plan.md
#
# This milestone overlays the existing PI-1..PI-7 milestones; each epic notes
# the PI it supports. Idempotent: skips creation if the milestone already exists.
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-Cyber-Defence-Platform"
TITLE="Framework Alignment: NIST CSF 2.0 / ISO 27001 / SOC-CMM / ATT&CK"
DESC="Bring the platform to the Strategic Framework Architecture: a NIST CSF 2.0 / ISO 27001 governance layer driving SOC-CMM operational maturity and MITRE ATT&CK detection coverage. Deliverables: Governance Pack, CSF 2.0 Profile, ISO 27001 SoA, SOC-CMM Baseline, ATT&CK Navigator Layer + Coverage Scorecard, Master Traceability Matrix. See docs/internal documents/UIW_Strategic_Framework_Alignment_Plan.md."

echo ""
echo "=== Creating Framework Alignment milestone ==="

# Skip if a milestone with this title already exists (idempotent).
existing=$(gh api "repos/${REPO}/milestones?state=all" \
  --jq ".[] | select(.title==\"${TITLE}\") | .number" || true)

if [[ -n "${existing}" ]]; then
  echo "  [exists] Milestone #${existing} already present — leaving as-is."
else
  gh api "repos/${REPO}/milestones" -X POST \
    -f title="${TITLE}" \
    -f state="open" \
    -f description="${DESC}" \
    --jq '"  [created] #\(.number): \(.title)"'
fi

echo ""
echo "Current milestone state:"
gh api "repos/${REPO}/milestones?state=all" --jq '.[] | "  \(.number): \(.title) [\(.state)]"'
