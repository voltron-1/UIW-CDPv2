#!/usr/bin/env bash
# =============================================================================
# capture_parity_pcap.sh — build a canonical parity pcap  [#171 / P2.5]
#
# Captures the fixed parity activity ONCE into a pcap so the identical packets
# can be replayed into BOTH Security Onion and the legacy ELK sensors for a
# deterministic comparison (same bytes in → any count delta is the pipeline, not
# run-to-run variance). Reuses the tests/anomaly_simulation sims to generate the
# activity while tcpdump records it.
#
# Run once — anywhere the sims can run, even against localhost on `lo`. Then ship
# the pcap to each sensor host and replay it with replay_parity_pcap.sh.
#
# Note on addresses: if you capture against localhost/off-segment, Zeek conn
# volume still compares fine, but Suricata HOME_NET rules may not match. For
# Suricata fidelity, target a host on the monitored segment (10.18.81.0/24).
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
[[ -f .env ]] && set -a && source .env && set +a

SIMS_DIR="${SIMS_DIR:-$HERE/../../tests/anomaly_simulation}"
PCAP_DIR="${PCAP_DIR:-$HERE/pcaps}"
CAPTURE_IFACE="${CAPTURE_IFACE:-lo}"
PARITY_TARGET="${PARITY_TARGET:-127.0.0.1}"
PARITY_ACTIVITIES="${PARITY_ACTIVITIES:-portscan ssh}"

command -v tcpdump >/dev/null 2>&1 || { echo "[ERROR] tcpdump not installed" >&2; exit 2; }
[[ -d "$SIMS_DIR" ]] || { echo "[ERROR] SIMS_DIR not found: $SIMS_DIR" >&2; exit 2; }
mkdir -p "$PCAP_DIR"

declare -A SIM_FOR=(
  [portscan]="sim_portscan.sh"
  [ssh]="sim_brute_ssh.sh"
  [malware]="sim_malware_download.sh"
)

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$PCAP_DIR/parity-$STAMP.pcap"

echo "============================================================"
echo " Capturing parity pcap"
echo " iface:      $CAPTURE_IFACE   target: $PARITY_TARGET"
echo " activities: $PARITY_ACTIVITIES"
echo " output:     $OUT   (tcpdump needs sudo)"
echo "============================================================"

sudo tcpdump -i "$CAPTURE_IFACE" -w "$OUT" "host $PARITY_TARGET" &
SUDO_PID=$!
stop_capture() { sudo pkill -INT -f "tcpdump.*-w $OUT" 2>/dev/null || true; }
trap stop_capture EXIT
sleep 1

for act in $PARITY_ACTIVITIES; do
  sim="${SIM_FOR[$act]:-}"
  if [[ -z "$sim" || ! -f "$SIMS_DIR/$sim" ]]; then
    echo "[WARN] skipping '$act' (no sim)" >&2
    continue
  fi
  echo
  echo "--- $act ($sim) ---"
  TARGET_HOST="$PARITY_TARGET" bash "$SIMS_DIR/$sim" \
    || echo "[WARN] '$act' sim exited non-zero (missing prereq / expected auth failure)" >&2
done

sleep 2                       # let trailing packets flush
stop_capture
wait "$SUDO_PID" 2>/dev/null || true
trap - EXIT

echo
echo "[+] pcap written: $OUT"
if command -v capinfos >/dev/null 2>&1; then
  capinfos -c -e "$OUT" 2>/dev/null || true
else
  ls -l "$OUT"
fi

cat <<MSG

Next — replay the SAME pcap into both stacks (identical packets), on each host:
  SO grid:    REPLAY_MODE=so-tcpreplay STACK_LABEL=SO  PCAP="$OUT" ./replay_parity_pcap.sh
  legacy ELK: REPLAY_MODE=tcpreplay REPLAY_IFACE=<mon-iface> STACK_LABEL=ELK PCAP="$OUT" ./replay_parity_pcap.sh
Then count events per stack for each replay window and fill pcap-parity-results-template.md.
MSG
