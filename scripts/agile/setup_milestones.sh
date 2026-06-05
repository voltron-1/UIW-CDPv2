#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — GitHub Milestone Setup
# Repo: voltron-1/UIW-Cyber-Defence-Platform
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-Cyber-Defence-Platform"

echo ""
echo "=== Step 1: Rename Milestone #1 to PI-1: Foundation Assessment ==="
gh api repos/${REPO}/milestones/1 -X PATCH \
  -f title="PI-1: Foundation Assessment" \
  -f description="Audit existing architecture, telemetry sources, and detection gaps. Infrastructure hardening baseline. Deliverables: Current State Document, Detection Inventory, Platform Gap Analysis, Technical Debt Register." \
  --jq '.title'

echo ""
echo "=== Step 2: Re-assign Milestone #2 issues (#22, #23) to Milestone #1 ==="
gh api repos/${REPO}/issues/22 -X PATCH -f milestone=1 --jq '.number,.milestone.title'
gh api repos/${REPO}/issues/23 -X PATCH -f milestone=1 --jq '.number,.milestone.title'

echo ""
echo "=== Step 3: Close Milestone #2 ==="
gh api repos/${REPO}/milestones/2 -X PATCH -f state="closed" --jq '.title,.state'

echo ""
echo "=== Step 4: Create PI-2 through PI-7 Milestones ==="

gh api repos/${REPO}/milestones -X POST \
  -f title="PI-2: Platform Engineering" \
  -f description="Migrate ELK to OpenSearch cluster, standardize index naming and telemetry pipelines, rebuild dashboards. Deliverables: OpenSearch Cluster, OpenSearch Dashboards, Updated Runbooks." \
  --jq '.number,.title'

gh api repos/${REPO}/milestones -X POST \
  -f title="PI-3: Detection Engineering Program" \
  -f description="Validate Sigma rules against OpenSearch, build MITRE ATT&CK coverage matrix, create detection QA process and rule lifecycle management. Deliverables: Detection Repository, ATT&CK Coverage Dashboard, Detection Validation Framework." \
  --jq '.number,.title'

gh api repos/${REPO}/milestones -X POST \
  -f title="PI-4: Adversary Validation" \
  -f description="Connect Adversary-in-a-Box to SOC subnet, author ATT&CK exercise playbooks, measure detection effectiveness, generate coverage reports. Deliverables: Purple-Team Validation Environment, Automated Coverage Reports, Attack Replay Library." \
  --jq '.number,.title'

gh api repos/${REPO}/milestones -X POST \
  -f title="PI-5: Multi-Agent SOAR Core" \
  -f description="Deploy Ollama infrastructure, build Agent Communication Bus, develop 4 containerized Python agents (Response, Threat Hunter, CTI, Compliance), implement audit logging. Deliverables: Agent Framework, Ollama Infrastructure, Agent Bus, Audit Log." \
  --jq '.number,.title'

gh api repos/${REPO}/milestones -X POST \
  -f title="PI-6: Student Analyst Operations" \
  -f description="Create operational workflows and training materials for Student Observer, Analyst, and Threat Hunter personas. Deliverables: Student Analyst Handbook, SOC Operations Guide, Training Exercises, Operational Procedures." \
  --jq '.number,.title'

gh api repos/${REPO}/milestones -X POST \
  -f title="PI-7: Capstone Demonstration" \
  -f description="Execute end-to-end operational sequence: attack generation, OpenSearch visibility, AI analysis, analyst mitigation. Deliverables: Capstone Presentation, Final Architecture Diagrams, Technical Documentation Package." \
  --jq '.number,.title'

echo ""
echo "=== All milestones complete ==="
echo ""
echo "Current milestone state:"
gh api repos/${REPO}/milestones --jq '.[] | "\(.number): \(.title) [\(.state)]"'
