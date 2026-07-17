#!/bin/bash
# scripts/migration/deploy_sigma_rules.sh
# Deploys custom Sigma rules to the Security Onion 3.1 local-sigma repository.

set -e

# Target paths as defined in SO 3.1 Salt state
SO_LOCAL_REPO="/nsm/rules/custom-local-repos/local-sigma"
SOURCE_DIR="$(dirname "$0")/../../rules/sigma"

echo "[*] Starting Sigma rule deployment to Security Onion 3.1..."

if [[ ! -d "$SO_LOCAL_REPO" ]]; then
    echo "[!] Error: Target directory $SO_LOCAL_REPO does not exist."
    echo "[!] Ensure this is being run on the Security Onion manager node."
    exit 1
fi

echo "[*] Copying Sigma rules from $SOURCE_DIR to $SO_LOCAL_REPO..."
cp "$SOURCE_DIR"/*.yml "$SO_LOCAL_REPO/"

echo "[*] Enforcing correct ownership (soccore:soccore) and permissions (644)..."
chown soccore:soccore "$SO_LOCAL_REPO"/*.yml
chmod 644 "$SO_LOCAL_REPO"/*.yml

echo "[*] Triggering Security Onion rule update..."
# SO 3.1 command to pull local rules and restart the detection engine
so-rule-update

echo "[+] Deployment complete! Check the Detections interface in SOC."
