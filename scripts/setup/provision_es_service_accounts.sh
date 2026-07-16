#!/usr/bin/env bash
# =============================================================================
# provision_es_service_accounts.sh — least-privilege ES users (es-least-priv-users)
# =============================================================================
# Creates the service accounts that let Logstash, the AI agent, and
# slo_metrics.py stop authenticating as the `elastic` superuser:
#   * logstash_internal  (role: logstash_writer)      — the Logstash pipeline's
#     ES output ONLY. Scoped to logstash-security-*.
#   * soc_agent_writer   (roles: soar_actions_writer,  — the agent's own outbound
#     soc_audit_appender)  writes (soar-actions-<tenant>, soc-audit-<tenant>).
#   * slo_metrics         (role: slo_metrics_reader)   — slo_metrics.py, run
#     standalone/via cron, not through docker-compose.
#
# logstash_internal and soc_agent_writer are DELIBERATELY separate identities,
# not one shared account: Logstash ingests untrusted network data, and giving
# it soc_audit_appender would let a compromised pipeline forge entries in the
# tamper-evident audit trail; giving the agent logstash_writer would hand it
# destructive index-admin reach (manage/delete) over the primary security
# index it never needs. Each account gets only the roles its own component's
# code path actually calls (see agent_app.py:594,707 vs logstash.conf's own
# ES output).
#
# Run apply_roles.sh FIRST — this script binds users to those role names, and
# while ES will accept a user referencing a role that doesn't exist yet, that
# user can't authenticate anything real until the role is actually applied.
#
# Idempotent: ES PUT upserts, so re-running just reconciles to desired state.
#
# Usage:  ./provision_es_service_accounts.sh
# Reads from scripts/setup/.env:
#   ELASTIC_PASSWORD    — bootstrap superuser, used ONLY to provision
#   LOGSTASH_ES_PASS     — password for the logstash_internal user (required)
#   AGENT_ES_PASS         — password for the soc_agent_writer user (required)
#   SLO_METRICS_PASSWORD — password for the slo_metrics user (required)
# Optional: ES_URL (default https://localhost:9200), ES_CA (default
# ./certs/ca/ca.crt relative to this script).
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$HERE/.env}"
[ -f "$ENV_FILE" ] && set -a && . "$ENV_FILE" && set +a

ES_URL="${ES_URL:-https://localhost:9200}"
CA="${ES_CA:-$HERE/certs/ca/ca.crt}"
: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD must be set (in .env or env)}"
: "${LOGSTASH_ES_PASS:?LOGSTASH_ES_PASS must be set (in .env or env)}"
: "${AGENT_ES_PASS:?AGENT_ES_PASS must be set (in .env or env)}"
: "${SLO_METRICS_PASSWORD:?SLO_METRICS_PASSWORD must be set (in .env or env)}"

# This script only ever sends the bootstrap SUPERUSER credential — unlike
# provision_kibana_system.sh's warn-and-continue, refuse outright rather than
# downgrade to unverified TLS for a superuser-carrying request.
[ -f "$CA" ] || { echo "[ERROR] CA not found at $CA; refusing to send the superuser credential over unverified TLS. Run generate_certs.sh, or set ES_CA." >&2; exit 1; }
CURL_TLS=(--cacert "$CA")

echo "[*] Verifying provisioning credential (elastic)…"
code=$(curl -sS "${CURL_TLS[@]}" -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" "$ES_URL/_security/_authenticate")
[[ "$code" == "200" ]] || { echo "[ERROR] elastic auth failed (HTTP $code). Fix ELASTIC_PASSWORD in .env."; exit 1; }

upsert_user() {
  local user="$1" pass="$2" roles_json="$3" full_name="$4"
  # Build the body with json.dumps, not shell string interpolation — a
  # password containing '"' or '\' would otherwise corrupt the JSON (or, in
  # the worst case, get interpreted as extra JSON keys).
  local body
  body=$(python3 -c '
import json, sys
pw, roles, name = sys.argv[1], json.loads(sys.argv[2]), sys.argv[3]
print(json.dumps({"password": pw, "roles": roles, "full_name": name}))
' "$pass" "$roles_json" "$full_name")
  code=$(curl -sS "${CURL_TLS[@]}" -o /dev/null -w '%{http_code}' -u "elastic:${ELASTIC_PASSWORD}" \
    -X PUT "$ES_URL/_security/user/$user" \
    -H 'Content-Type: application/json' \
    -d "$body")
  if [[ "$code" =~ ^20 ]]; then
    printf '    user %-18s -> HTTP %s\n' "$user" "$code"
  else
    echo "[ERROR] user $user upsert failed (HTTP $code)" >&2
    exit 1
  fi
}

echo "[*] Upserting 'logstash_internal' (logstash_writer)…"
upsert_user "logstash_internal" "$LOGSTASH_ES_PASS" '["logstash_writer"]' \
  "Logstash writer (UIW-CDPv2)"

echo "[*] Upserting 'soc_agent_writer' (soar_actions_writer + soc_audit_appender)…"
upsert_user "soc_agent_writer" "$AGENT_ES_PASS" '["soar_actions_writer","soc_audit_appender"]' \
  "SOC AI agent writer (UIW-CDPv2)"

echo "[*] Upserting 'slo_metrics' (slo_metrics_reader)…"
upsert_user "slo_metrics" "$SLO_METRICS_PASSWORD" '["slo_metrics_reader"]' \
  "SLO metrics (UIW-CDPv2)"

echo "[+] Done. Set in .env, then restart the affected services:"
echo "    LOGSTASH_ES_USER=logstash_internal"
echo "    LOGSTASH_ES_PASS=<the password you gave LOGSTASH_ES_PASS above>"
echo "    AGENT_ES_USER=soc_agent_writer"
echo "    AGENT_ES_PASS=<the password you gave AGENT_ES_PASS above>"
echo "    Run slo_metrics.py with ES_USER=slo_metrics ES_PASS=<its password>"
echo "    docker compose up -d logstash ai-agent"
