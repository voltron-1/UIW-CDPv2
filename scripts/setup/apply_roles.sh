#!/usr/bin/env bash
# =============================================================================
# apply_roles.sh — install the least-privilege RBAC roles (es-role-definitions)
# =============================================================================
# Applies every role in configs/elasticsearch/roles/*.json to Elasticsearch so
# the role definitions are version-controlled, not ad-hoc. Services use
# logstash_writer / soc_audit_appender / slo_metrics_reader / soc_agent_cases;
# humans use soc_analyst / soc_detection_engineer / soc_admin. No human or
# service should need the `elastic` superuser once the matching accounts are
# provisioned (see provision_es_service_accounts.sh).
#
# Idempotent: each role is a PUT (upsert), so re-running just reconciles to
# the committed definitions. Safe to run on every deploy.
#
# Usage:  ./apply_roles.sh
# Reads from scripts/setup/.env: ELASTIC_PASSWORD (required — the bootstrap
# superuser is used ONLY to provision, never at runtime by any service).
# Optional: ES_URL (default https://localhost:9200), ES_CA (default
# ./certs/ca/ca.crt relative to this script).
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$HERE/.env}"
[ -f "$ENV_FILE" ] && set -a && . "$ENV_FILE" && set +a

ES_URL="${ES_URL:-https://localhost:9200}"
CA="${ES_CA:-$HERE/certs/ca/ca.crt}"
: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD must be set (in .env or env)}"

# This script only ever sends the bootstrap SUPERUSER credential — refuse
# outright rather than downgrade to unverified TLS for it.
[ -f "$CA" ] || { echo "[ERROR] CA not found at $CA; refusing to send the superuser credential over unverified TLS. Run generate_certs.sh, or set ES_CA." >&2; exit 1; }
CURL_TLS=(--cacert "$CA")

echo "[*] Waiting for Elasticsearch to be reachable at $ES_URL ..."
for i in $(seq 1 30); do
  if curl -sSf "${CURL_TLS[@]}" -u "elastic:$ELASTIC_PASSWORD" "$ES_URL/_cluster/health" >/dev/null; then
    break
  fi
  sleep 5
  [ "$i" = 30 ] && { echo "[ERROR] ES not reachable after 150s." >&2; exit 1; }
done

for f in "$REPO_ROOT"/configs/elasticsearch/roles/*.json; do
  role="$(basename "$f" .json)"
  code=$(curl -sS -o /dev/null -w '%{http_code}' "${CURL_TLS[@]}" \
    -u "elastic:$ELASTIC_PASSWORD" -X PUT "$ES_URL/_security/role/$role" \
    -H 'Content-Type: application/json' --data-binary "@$f")
  if [[ "$code" =~ ^20 ]]; then
    printf '    role %-24s -> HTTP %s\n' "$role" "$code"
  else
    echo "[ERROR] role $role upsert failed (HTTP $code)" >&2
    exit 1
  fi
done

echo "[+] Done. RBAC roles installed. Run provision_es_service_accounts.sh next to"
echo "    create the logstash_internal / slo_metrics service users bound to them."
