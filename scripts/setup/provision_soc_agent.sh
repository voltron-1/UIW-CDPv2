#!/bin/bash
# =============================================================================
# provision_soc_agent.sh — least-privilege Kibana Cases user for the AI agent
# =============================================================================
# WS2.3: the SOAR agent opens/updates Kibana Cases. Per CDP least-privilege, it
# must NOT run as `elastic`. This script provisions, idempotently:
#   * user  `$KIBANA_AGENT_USER` (default soc_agent), bound to the
#     `soc_agent_cases` role (Kibana generalCases: all, all spaces)
#
# Run apply_roles.sh FIRST (es-role-definitions, Workstream E) — that's what
# creates the `soc_agent_cases` role, from the single committed source of
# truth at configs/elasticsearch/roles/soc_agent_cases.json. This script used
# to define that role itself, inline, via Kibana's role API — which put two
# independently-hand-maintained copies of the same role in the repo (this
# script's inline body vs. the committed JSON) with no way to keep them in
# sync. Now there's exactly one.
#
# Idempotent: ES PUT upserts, so re-running just reconciles to desired state.
# Safe to run on every deploy (e.g. from an init container).
#
# Reads from scripts/setup/.env:
#   ELASTIC_PASSWORD   — a superuser credential used ONLY to provision (not by the agent)
#   KIBANA_AGENT_USER  — the user to create (default: soc_agent)
#   KIBANA_AGENT_PASS  — that user's password (required)
#
# Usage:  ./provision_soc_agent.sh
# =============================================================================
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
[[ -f .env ]] || { echo "ERROR: .env not found in $(pwd)"; exit 1; }
# shellcheck disable=SC1091
source .env

ES_URL="${ES_URL:-https://localhost:9200}"
ROLE_NAME="${ROLE_NAME:-soc_agent_cases}"
KIBANA_AGENT_USER="${KIBANA_AGENT_USER:-soc_agent}"
CA="${ES_CA:-$(pwd)/certs/ca/ca.crt}"

: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD must be set in .env}"
: "${KIBANA_AGENT_PASS:?KIBANA_AGENT_PASS must be set in .env}"

# This script only ever sends the bootstrap SUPERUSER credential — refuse
# outright rather than downgrade to unverified TLS for it.
[ -f "$CA" ] || { echo "ERROR: CA not found at $CA; refusing to send the superuser credential over unverified TLS. Run generate_certs.sh, or set ES_CA."; exit 1; }
CURL_TLS=(--cacert "$CA")

echo "[*] Verifying provisioning credential (elastic)…"
code=$(curl -sS "${CURL_TLS[@]}" -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" "${ES_URL}/_security/_authenticate")
[[ "$code" == "200" ]] || { echo "ERROR: elastic auth failed (HTTP $code). Fix ELASTIC_PASSWORD in .env."; exit 1; }

echo "[*] Checking role '${ROLE_NAME}' exists (run apply_roles.sh first if this fails)…"
code=$(curl -sS "${CURL_TLS[@]}" -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" "${ES_URL}/_security/role/${ROLE_NAME}")
[[ "$code" == "200" ]] || { echo "ERROR: role '${ROLE_NAME}' not found (HTTP $code). Run ./apply_roles.sh first."; exit 1; }

echo "[*] Upserting ES user '${KIBANA_AGENT_USER}' with role '${ROLE_NAME}'…"
# Build the body with json.dumps, not shell string interpolation — a
# password containing '"' or '\' would otherwise corrupt the JSON.
body=$(python3 -c '
import json, sys
pw, role = sys.argv[1], sys.argv[2]
print(json.dumps({"password": pw, "roles": [role], "full_name": "SOC AI Agent (Cases)"}))
' "$KIBANA_AGENT_PASS" "$ROLE_NAME")
code=$(curl -sS "${CURL_TLS[@]}" -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT "${ES_URL}/_security/user/${KIBANA_AGENT_USER}" \
  -H 'Content-Type: application/json' \
  -d "$body")
[[ "$code" =~ ^20 ]] || { echo "ERROR: user upsert failed (HTTP $code)"; exit 1; }
echo "    user OK (HTTP $code)"

echo "[*] Verifying '${KIBANA_AGENT_USER}' can authenticate…"
code=$(curl -sS "${CURL_TLS[@]}" -o /dev/null -w '%{http_code}' -u "${KIBANA_AGENT_USER}:${KIBANA_AGENT_PASS}" "${ES_URL}/_security/_authenticate")
[[ "$code" == "200" ]] || { echo "ERROR: ${KIBANA_AGENT_USER} auth failed (HTTP $code)"; exit 1; }

echo "[+] Done. '${KIBANA_AGENT_USER}' is provisioned with Kibana Cases access."
echo "    Restart the agent so it picks up KIBANA_AGENT_USER/PASS:  docker compose up -d ai-agent"
