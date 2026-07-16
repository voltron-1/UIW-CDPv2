#!/bin/bash
# Setup Elasticsearch Ingest Pipelines for ABAC Enrichment in Security Onion 3.1
# This replaces the Logstash `translate` filters used in the legacy stack.

set -euo pipefail

ES_URL="https://localhost:9200"
ES_CREDS="elastic:changeme" # To be replaced by proper least-priv credentials in SO
CACERT="/etc/pki/tls/certs/ca-bundle.crt" # SO CA path

echo "[*] Creating ABAC lookup index (abac-attributes)..."
curl -s -k -X PUT "$ES_URL/abac-attributes" -u "$ES_CREDS" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "attribute_name": { "type": "keyword" },
      "allowed_values": { "type": "keyword" },
      "criticality": { "type": "keyword" }
    }
  }
}'

echo ""
echo "[*] Creating Logon Type lookup index (windows-logon-type)..."
curl -s -k -X PUT "$ES_URL/windows-logon-type" -u "$ES_CREDS" -H 'Content-Type: application/json' -d'
{
  "mappings": {
    "properties": {
      "logon_type": { "type": "keyword" },
      "description": { "type": "keyword" },
      "risk_level": { "type": "keyword" }
    }
  }
}'

echo ""
echo "[*] Creating Enrichment Policies..."
curl -s -k -X PUT "$ES_URL/_enrich/policy/abac_policy" -u "$ES_CREDS" -H 'Content-Type: application/json' -d'
{
  "match": {
    "indices": "abac-attributes",
    "match_field": "attribute_name",
    "enrich_fields": ["allowed_values", "criticality"]
  }
}'

curl -s -k -X PUT "$ES_URL/_enrich/policy/logon_type_policy" -u "$ES_CREDS" -H 'Content-Type: application/json' -d'
{
  "match": {
    "indices": "windows-logon-type",
    "match_field": "logon_type",
    "enrich_fields": ["description", "risk_level"]
  }
}'

echo ""
echo "[*] Executing Enrichment Policies..."
curl -s -k -X POST "$ES_URL/_enrich/policy/abac_policy/_execute" -u "$ES_CREDS"
curl -s -k -X POST "$ES_URL/_enrich/policy/logon_type_policy/_execute" -u "$ES_CREDS"

echo ""
echo "[*] Creating Ingest Pipeline (uiw_abac_enrichment)..."
curl -s -k -X PUT "$ES_URL/_ingest/pipeline/uiw_abac_enrichment" -u "$ES_CREDS" -H 'Content-Type: application/json' -d'
{
  "description": "Enrich events with ABAC and Logon Type metadata",
  "processors": [
    {
      "enrich": {
        "policy_name": "abac_policy",
        "field": "user.name",
        "target_field": "user.abac",
        "ignore_missing": true
      }
    },
    {
      "enrich": {
        "policy_name": "logon_type_policy",
        "field": "winlog.logon.type",
        "target_field": "winlog.logon.enrichment",
        "ignore_missing": true
      }
    }
  ]
}'

echo ""
echo "[*] Setup complete. Verify pipelines via Kibana/SOC console."
