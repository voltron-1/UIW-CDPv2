#!/bin/bash
# =============================================================================
# provision_soc_agent.sh — least-privilege Kibana Cases user for the AI agent
# =============================================================================
# WS2.3: the SOAR agent opens/updates Kibana Cases. Per CDP least-privilege, it
# must NOT run as `elastic`. This script provisions, idempotently:
#   * role  `soc_agent_cases`  — only the Kibana `generalCases: all` privilege
#   * user  `$KIBANA_AGENT_USER` (default soc_agent) holding that role
#
# Idempotent: ES/Kibana PUT upserts, so re-running just reconciles to desired
# state. Safe to run on every deploy (e.g. from an init container).
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
KIBANA_URL="${KIBANA_URL:-http://localhost:5601}"
ROLE_NAME="${ROLE_NAME:-soc_agent_cases}"
KIBANA_AGENT_USER="${KIBANA_AGENT_USER:-soc_agent}"

: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD must be set in .env}"
: "${KIBANA_AGENT_PASS:?KIBANA_AGENT_PASS must be set in .env}"

echo "[*] Verifying provisioning credential (elastic)…"
code=$(curl -s -k -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" "${ES_URL}/_security/_authenticate")
[[ "$code" == "200" ]] || { echo "ERROR: elastic auth failed (HTTP $code). Fix ELASTIC_PASSWORD in .env."; exit 1; }

echo "[*] Upserting Kibana role '${ROLE_NAME}' (generalCases: all, all spaces)…"
code=$(curl -s -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT "${KIBANA_URL}/api/security/role/${ROLE_NAME}" \
  -H "kbn-xsrf: true" -H "Content-Type: application/json" \
  -d '{"elasticsearch":{"cluster":[],"indices":[]},"kibana":[{"base":[],"feature":{"generalCases":["all"]},"spaces":["*"]}]}')
[[ "$code" =~ ^20 ]] || { echo "ERROR: role upsert failed (HTTP $code)"; exit 1; }
echo "    role OK (HTTP $code)"

echo "[*] Upserting ES user '${KIBANA_AGENT_USER}' with role '${ROLE_NAME}'…"
code=$(curl -s -k -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT "${ES_URL}/_security/user/${KIBANA_AGENT_USER}" \
  -H 'Content-Type: application/json' \
  -d "{\"password\":\"${KIBANA_AGENT_PASS}\",\"roles\":[\"${ROLE_NAME}\"],\"full_name\":\"SOC AI Agent (Cases)\"}")
[[ "$code" =~ ^20 ]] || { echo "ERROR: user upsert failed (HTTP $code)"; exit 1; }
echo "    user OK (HTTP $code)"

echo "[*] Verifying '${KIBANA_AGENT_USER}' can authenticate…"
code=$(curl -s -k -o /dev/null -w '%{http_code}' -u "${KIBANA_AGENT_USER}:${KIBANA_AGENT_PASS}" "${ES_URL}/_security/_authenticate")
[[ "$code" == "200" ]] || { echo "ERROR: ${KIBANA_AGENT_USER} auth failed (HTTP $code)"; exit 1; }

echo "[+] Done. '${KIBANA_AGENT_USER}' is provisioned with Kibana Cases access."
echo "    Restart the agent so it picks up KIBANA_AGENT_USER/PASS:  docker compose up -d ai-agent"
