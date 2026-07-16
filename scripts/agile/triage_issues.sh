#!/usr/bin/env bash
# =============================================================================
# UIW Cyber Defence Platform — Issue Triage
# Closes 8 duplicate issues and relabels/retitles 16 kept issues
# Repo: voltron-1/UIW-CDPv2
# =============================================================================
set -euo pipefail

REPO="voltron-1/UIW-CDPv2"

echo ""
echo "========================================================"
echo "  PHASE 1: Close 8 Duplicate Issues"
echo "========================================================"

close_duplicate() {
  local num="$1"
  local canonical="$2"
  gh api repos/${REPO}/issues/${num}/comments -X POST \
    -f body="Closing as duplicate of #${canonical}. All work tracked in #${canonical} going forward." > /dev/null
  gh api repos/${REPO}/issues/${num} -X PATCH -f state="closed" --jq '"  [closed] #\(.number): \(.title)"'
}

close_duplicate 1  9
close_duplicate 2  10
close_duplicate 3  11
close_duplicate 4  16
close_duplicate 5  17
close_duplicate 19 6
close_duplicate 21 7
close_duplicate 24 8

echo ""
echo "========================================================"
echo "  PHASE 2: Relabel & Retitle 16 Kept Issues"
echo "========================================================"

relabel_issue() {
  local num="$1"
  local milestone="$2"
  shift 2
  local labels=("$@")

  # Build comma-separated label JSON array
  local label_json
  label_json=$(printf '%s\n' "${labels[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")

  gh api repos/${REPO}/issues/${num} -X PATCH \
    -f milestone="${milestone}" \
    --input - <<EOF > /dev/null
{"labels": $(echo $label_json)}
EOF
  echo "  [relabeled] #${num}"
}

retitle_and_relabel() {
  local num="$1"
  local title="$2"
  local milestone="$3"
  shift 3
  local labels=("$@")

  local label_json
  label_json=$(printf '%s\n' "${labels[@]}" | python3 -c "import sys,json; print(json.dumps([l.strip() for l in sys.stdin]))")

  gh api repos/${REPO}/issues/${num} -X PATCH \
    -f title="${title}" \
    -f milestone="${milestone}" \
    --input - <<EOF > /dev/null
{"labels": $(echo $label_json)}
EOF
  echo "  [updated]   #${num}: ${title}"
}

# ---------- PI-1 Issues ----------
echo ""
echo "--- PI-1: Foundation Assessment ---"
retitle_and_relabel 6  "Audit and reset factory-default credentials on UIW infrastructure" 1 \
  "PI-1: Foundation Assessment" "type: task" "priority: critical"

retitle_and_relabel 7  "Configure VLAN segmentation for SOC management traffic" 1 \
  "PI-1: Foundation Assessment" "type: task" "priority: high"

retitle_and_relabel 8  "Apply CIS Benchmark Level 2 to Ubuntu host server" 1 \
  "PI-1: Foundation Assessment" "type: task" "priority: critical"

retitle_and_relabel 20 "Disable Telnet and HTTP — enforce SSH v2 and HTTPS on all management interfaces" 1 \
  "PI-1: Foundation Assessment" "type: task" "priority: critical"

retitle_and_relabel 22 "Enable TCP SYN cookies on all Linux nodes to resist SYN-flood attacks" 1 \
  "PI-1: Foundation Assessment" "type: task" "priority: high"

retitle_and_relabel 23 "Deploy internal CA and enforce mTLS for all inter-service communications" 1 \
  "PI-1: Foundation Assessment" "type: task" "priority: high"

# ---------- PI-2 Issues ----------
echo ""
echo "--- PI-2: Platform Engineering ---"
retitle_and_relabel 9  "Deploy OpenSearch cluster (migrating from Elasticsearch)" 3 \
  "PI-2: Platform Engineering" "type: task" "priority: critical"

retitle_and_relabel 10 "Deploy Suricata NIDS and configure core switch SPAN port" 3 \
  "PI-2: Platform Engineering" "type: task" "priority: high"

retitle_and_relabel 11 "Install Wazuh HIDS agents on lab endpoints (agent-only, forward to OpenSearch)" 3 \
  "PI-2: Platform Engineering" "type: task" "priority: high"

# ---------- PI-3 Issues ----------
echo ""
echo "--- PI-3: Detection Engineering ---"
retitle_and_relabel 18 "Map all validated detections to MITRE ATT&CK framework" 4 \
  "PI-3: Detection Engineering" "type: task" "priority: high"

# ---------- PI-4 Issues ----------
echo ""
echo "--- PI-4: Adversary Validation ---"
retitle_and_relabel 16 "Execute adversary emulation: Nmap sweeps and SSH brute-force simulations" 5 \
  "PI-4: Adversary Validation" "type: task" "priority: high"

retitle_and_relabel 17 "Validate AI triage and human-in-the-loop containment workflow" 5 \
  "PI-4: Adversary Validation" "type: task" "priority: critical"

# ---------- PI-5 Issues ----------
echo ""
echo "--- PI-5: Multi-Agent SOAR Core ---"
retitle_and_relabel 12 "Deploy Response Agent container (Multi-Agent SOAR Core)" 6 \
  "PI-5: Multi-Agent SOAR" "type: task" "priority: critical"

retitle_and_relabel 13 "Configure OpenSearch alerting webhook routing to Response Agent" 6 \
  "PI-5: Multi-Agent SOAR" "type: task" "priority: high"

retitle_and_relabel 14 "Write active mitigation script (iptables containment blueprint)" 6 \
  "PI-5: Multi-Agent SOAR" "type: task" "priority: high"

retitle_and_relabel 15 "Integrate external OSINT APIs (VirusTotal, AlienVault OTX) for CTI Agent" 6 \
  "PI-5: Multi-Agent SOAR" "type: task" "priority: high"

echo ""
echo "========================================================"
echo "  Issue triage complete"
echo "========================================================"
