#!/usr/bin/env bash
# provision_kibana_system.sh — set the built-in kibana_system password inside ES.
#
# WHY (issue #114): docker-compose passes KIBANA_PASSWORD to the Kibana container,
# but that password must ALSO be set on the kibana_system user *inside* Elasticsearch
# after first boot, or Kibana fails to authenticate. This script does that, using the
# bootstrap ELASTIC_PASSWORD. Run it once, after ES is healthy.
#
# Usage:  ./provision_kibana_system.sh
# Reads ELASTIC_PASSWORD and KIBANA_PASSWORD from scripts/setup/.env (or the env).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$HERE/.env}"
[ -f "$ENV_FILE" ] && set -a && . "$ENV_FILE" && set +a

ES_URL="${ES_URL:-https://localhost:9200}"
CA="${ES_CA:-$HERE/certs/ca/ca.crt}"
: "${ELASTIC_PASSWORD:?ELASTIC_PASSWORD must be set (in .env or env)}"
: "${KIBANA_PASSWORD:?KIBANA_PASSWORD must be set (in .env or env)}"

CURL_TLS=(--cacert "$CA")
[ -f "$CA" ] || { echo "[WARN] CA not found at $CA; falling back to -k (insecure)."; CURL_TLS=(-k); }

echo "[*] Waiting for Elasticsearch to be reachable at $ES_URL ..."
for i in $(seq 1 30); do
  if curl -sf "${CURL_TLS[@]}" -u "elastic:$ELASTIC_PASSWORD" "$ES_URL/_cluster/health" >/dev/null; then
    break
  fi
  sleep 5
  [ "$i" = 30 ] && { echo "[ERROR] ES not reachable after 150s." >&2; exit 1; }
done

echo "[*] Setting kibana_system password ..."
code=$(curl -s -o /dev/null -w '%{http_code}' "${CURL_TLS[@]}" \
  -u "elastic:$ELASTIC_PASSWORD" -X POST \
  "$ES_URL/_security/user/kibana_system/_password" \
  -H 'Content-Type: application/json' \
  -d "{\"password\":\"$KIBANA_PASSWORD\"}")

if [ "$code" = "200" ]; then
  echo "[OK] kibana_system password set. Restart Kibana if it was already running."
else
  echo "[ERROR] Failed to set kibana_system password (HTTP $code)." >&2
  exit 1
fi
