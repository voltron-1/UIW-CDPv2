#!/usr/bin/env bash
# =============================================================================
# replay_parity_pcap.sh — replay a canonical pcap into ONE sensor  [#171 / P2.5]
#
# Run once per stack (SO, then legacy ELK) with the SAME pcap so both sensors
# process identical packets. Times the replay window and prints a block to record.
# Run this ON the sensor host — the replay binary lives there.
#
# Modes (REPLAY_MODE):
#   so-tcpreplay : SO grid — `sudo so-tcpreplay <pcap>` (replays onto SO's monitor NIC)
#   tcpreplay    : any host — `sudo tcpreplay -i <REPLAY_IFACE> <pcap>`
#   zeek         : legacy offline — `zeek -r <pcap>` (writes logs for filebeat pickup)
#
# Usage:
#   REPLAY_MODE=so-tcpreplay STACK_LABEL=SO  PCAP=parity.pcap ./replay_parity_pcap.sh
#   REPLAY_MODE=tcpreplay REPLAY_IFACE=eth1 STACK_LABEL=ELK PCAP=parity.pcap ./replay_parity_pcap.sh
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
[[ -f .env ]] && set -a && source .env && set +a

PCAP="${PCAP:-${1:-}}"
REPLAY_MODE="${REPLAY_MODE:-tcpreplay}"
REPLAY_IFACE="${REPLAY_IFACE:-}"
STACK_LABEL="${STACK_LABEL:-unknown}"

[[ -n "$PCAP" ]] || { echo "[ERROR] set PCAP=<file.pcap> (or pass as arg 1)" >&2; exit 2; }
[[ -f "$PCAP" ]] || { echo "[ERROR] pcap not found: $PCAP" >&2; exit 2; }

case "$REPLAY_MODE" in
  so-tcpreplay) BIN=so-tcpreplay; CMD=(sudo so-tcpreplay "$PCAP") ;;
  tcpreplay)
    [[ -n "$REPLAY_IFACE" ]] || { echo "[ERROR] tcpreplay mode needs REPLAY_IFACE=<iface>" >&2; exit 2; }
    BIN=tcpreplay; CMD=(sudo tcpreplay -i "$REPLAY_IFACE" "$PCAP") ;;
  zeek) BIN=zeek; CMD=(zeek -r "$PCAP") ;;
  *) echo "[ERROR] unknown REPLAY_MODE '$REPLAY_MODE' (so-tcpreplay|tcpreplay|zeek)" >&2; exit 2 ;;
esac

if ! command -v "$BIN" >/dev/null 2>&1; then
  echo "[ERROR] '$BIN' not found on this host — run this on the $STACK_LABEL sensor host." >&2
  echo "        Command would be: ${CMD[*]}" >&2
  exit 3
fi

WINDOW_START="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "[*] [$STACK_LABEL] replaying $PCAP via $REPLAY_MODE"
echo "[*] start (UTC): $WINDOW_START"
"${CMD[@]}"
WINDOW_END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat <<MSG

[+] [$STACK_LABEL] replay complete.
    window (UTC): $WINDOW_START .. $WINDOW_END
    pcap:         $PCAP  (mode: $REPLAY_MODE)

Next: count events for THIS window in the $STACK_LABEL stack and record them in
pcap-parity-results-template.md (one row per stack, SAME pcap):
  - SO:  SOC Hunt / Alerts, event.module:zeek + event.module:suricata
  - ELK: index logstash-security-* (cf. ../../tests/anomaly_simulation/verify_detections.py)
MSG
