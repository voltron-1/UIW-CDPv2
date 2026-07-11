#!/bin/bash
# =============================================================================
# generate_certs.sh — Internal CA + service certificates  (CDP §6)
# =============================================================================
# Re-enables transport security by minting a semester-scoped internal CA and
# per-service certificates for the SOC stack. Run this ONCE before
# `docker compose up`. Re-run each semester to rotate (CDP §6).
#
#   ./generate_certs.sh
#
# Produces (under ./certs, git-ignored):
#   certs/ca/ca.crt                 internal CA certificate (trust anchor)
#   certs/ca/ca.key                 CA private key (KEEP OFF GIT)
#   certs/es/es.crt|es.key          Elasticsearch node cert (http + transport)
#   certs/logstash/logstash.crt|.key  Logstash server cert for the Beats input
#                                      (mTLS: Filebeat/Winlogbeat verify this and
#                                      present their own CA-signed client cert)
#   certs/filebeat/filebeat.crt|.key  Client cert every Filebeat/endpoint
#                                      shipper presents to the Beats input
#
# The transport layer is configured with verification_mode=certificate, so
# every node/client must present a cert signed by this CA — i.e. mTLS.
# =============================================================================
set -euo pipefail
# Private keys must never be world/group-readable, even for the instant
# between openssl creating the file and the chmod at the end of this script.
umask 077

CERT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/certs"
CA_DIR="$CERT_DIR/ca"
ES_DIR="$CERT_DIR/es"
LOGSTASH_DIR="$CERT_DIR/logstash"
FILEBEAT_DIR="$CERT_DIR/filebeat"
DAYS=180   # one semester; rotate on expiry

mkdir -p "$CA_DIR" "$ES_DIR" "$LOGSTASH_DIR" "$FILEBEAT_DIR"

# Each cert pair is gated on its OWN existence, not just the CA's, so running
# this script again on a deployment that already has a CA + ES cert (e.g. to
# pick up a hardening update that adds new cert types) still generates the
# ones that are actually missing instead of silently no-op'ing on everything.
if [[ -f "$CA_DIR/ca.crt" ]]; then
  echo "[=] CA already exists at $CA_DIR/ca.crt — delete ./certs to regenerate. Skipping."
else
  echo "[*] Generating internal CA (valid ${DAYS} days)..."
  openssl genrsa -out "$CA_DIR/ca.key" 4096
  openssl req -x509 -new -nodes -key "$CA_DIR/ca.key" -sha256 -days "$DAYS" \
    -subj "/O=UIW-SOC/OU=CDP/CN=UIW-SOC Internal CA" \
    -out "$CA_DIR/ca.crt"
fi

if [[ -f "$ES_DIR/es.crt" ]]; then
  echo "[=] Elasticsearch cert already exists at $ES_DIR/es.crt — skipping."
else
  echo "[*] Generating Elasticsearch node certificate..."
  openssl genrsa -out "$ES_DIR/es.key" 4096
  # SANs cover the in-network service name and localhost for host access.
  openssl req -new -key "$ES_DIR/es.key" \
    -subj "/O=UIW-SOC/OU=CDP/CN=elasticsearch" \
    -out "$ES_DIR/es.csr"

  cat > "$ES_DIR/es.ext" <<'EOF'
subjectAltName = DNS:elasticsearch, DNS:localhost, IP:127.0.0.1
extendedKeyUsage = serverAuth, clientAuth
EOF

  openssl x509 -req -in "$ES_DIR/es.csr" \
    -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -sha256 -days "$DAYS" -extfile "$ES_DIR/es.ext" \
    -out "$ES_DIR/es.crt"

  rm -f "$ES_DIR/es.csr" "$ES_DIR/es.ext"
fi

if [[ -f "$LOGSTASH_DIR/logstash.crt" ]]; then
  echo "[=] Logstash cert already exists at $LOGSTASH_DIR/logstash.crt — skipping."
else
  echo "[*] Generating Logstash server certificate (Beats input TLS/mTLS)..."
  openssl genrsa -out "$LOGSTASH_DIR/logstash.key.pkcs1" 4096
  # Logstash's Beats input plugin requires a PKCS8-format private key, not the
  # PKCS1 default openssl genrsa produces — convert at generation time so no
  # runtime conversion step is needed.
  openssl pkcs8 -topk8 -inform PEM -in "$LOGSTASH_DIR/logstash.key.pkcs1" \
    -out "$LOGSTASH_DIR/logstash.key" -nocrypt
  rm -f "$LOGSTASH_DIR/logstash.key.pkcs1"
  openssl req -new -key "$LOGSTASH_DIR/logstash.key" \
    -subj "/O=UIW-SOC/OU=CDP/CN=logstash" \
    -out "$LOGSTASH_DIR/logstash.csr"

  cat > "$LOGSTASH_DIR/logstash.ext" <<'EOF'
subjectAltName = DNS:logstash, DNS:localhost, IP:127.0.0.1
extendedKeyUsage = serverAuth, clientAuth
EOF

  openssl x509 -req -in "$LOGSTASH_DIR/logstash.csr" \
    -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -sha256 -days "$DAYS" -extfile "$LOGSTASH_DIR/logstash.ext" \
    -out "$LOGSTASH_DIR/logstash.crt"

  rm -f "$LOGSTASH_DIR/logstash.csr" "$LOGSTASH_DIR/logstash.ext"
fi

if [[ -f "$FILEBEAT_DIR/filebeat.crt" ]]; then
  echo "[=] Filebeat cert already exists at $FILEBEAT_DIR/filebeat.crt — skipping."
else
  echo "[*] Generating Filebeat client certificate (Beats input mTLS)..."
  openssl genrsa -out "$FILEBEAT_DIR/filebeat.key" 4096
  openssl req -new -key "$FILEBEAT_DIR/filebeat.key" \
    -subj "/O=UIW-SOC/OU=CDP/CN=filebeat" \
    -out "$FILEBEAT_DIR/filebeat.csr"

  cat > "$FILEBEAT_DIR/filebeat.ext" <<'EOF'
extendedKeyUsage = clientAuth
EOF

  openssl x509 -req -in "$FILEBEAT_DIR/filebeat.csr" \
    -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" -CAcreateserial \
    -sha256 -days "$DAYS" -extfile "$FILEBEAT_DIR/filebeat.ext" \
    -out "$FILEBEAT_DIR/filebeat.crt"

  rm -f "$FILEBEAT_DIR/filebeat.csr" "$FILEBEAT_DIR/filebeat.ext"
fi

chmod 600 "$CA_DIR/ca.key" "$ES_DIR/es.key" "$LOGSTASH_DIR/logstash.key" "$FILEBEAT_DIR/filebeat.key"

echo "[+] Certificates written to $CERT_DIR"
echo "[!] Set ELASTIC_PASSWORD in scripts/setup/.env before 'docker compose up'."
echo "[!] Copy certs/ca/ca.crt and certs/filebeat/filebeat.{crt,key} to every"
echo "    Filebeat/Winlogbeat host (paths configurable via FILEBEAT_CA/_CERT/_KEY)."
