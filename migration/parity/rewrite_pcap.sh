#!/usr/bin/env bash
# =============================================================================
# rewrite_pcap.sh — remap a pcap's IPs into HOME_NET  [#171 / P2.5]
#
# So Suricata's HOME_NET rules match on replay, rewrite every address in
# MATCH_CIDR to the same host in HOME_NET_CIDR (host bits preserved, e.g.
# 192.168.126.128 -> 10.18.81.128), for BOTH source and destination, then fix
# checksums. Run once after capture, before shipping the pcap to the sensors —
# this decouples where you captured from what HOME_NET expects, so you never
# have to reinstall SO or put the grid on a real 10.x network.
#
# Requires DISTINCT src/dst in the input: capture against a NON-loopback target
# on a real Ethernet interface. A loopback capture (src=dst=127.0.0.1, DLT_NULL)
# can't be split into attacker/target; set TO_ETHERNET=1 to add an Ethernet
# header for replay, but the self-addressing limitation remains.
#
# Usage:
#   MATCH_CIDR=192.168.126.0/24 HOME_NET_CIDR=10.18.81.0/24 \
#     ./rewrite_pcap.sh pcaps/parity-<stamp>.pcap pcaps/parity-<stamp>-homenet.pcap
# =============================================================================
set -euo pipefail

IN="${1:-${IN:-}}"
OUT="${2:-${OUT:-}}"
MATCH_CIDR="${MATCH_CIDR:-192.168.126.0/24}"
HOME_NET_CIDR="${HOME_NET_CIDR:-10.18.81.0/24}"
TO_ETHERNET="${TO_ETHERNET:-0}"
ENET_SMAC="${ENET_SMAC:-00:11:22:33:44:01}"
ENET_DMAC="${ENET_DMAC:-00:11:22:33:44:02}"

command -v tcprewrite >/dev/null 2>&1 || { echo "[ERROR] tcprewrite not installed (part of the tcpreplay suite: apt install tcpreplay)" >&2; exit 2; }
[[ -n "$IN"  ]] || { echo "[ERROR] input pcap: pass as arg 1 or set IN=" >&2; exit 2; }
[[ -f "$IN"  ]] || { echo "[ERROR] pcap not found: $IN" >&2; exit 2; }
[[ -n "$OUT" ]] || { echo "[ERROR] output pcap: pass as arg 2 or set OUT=" >&2; exit 2; }

# --pnat rewrites both source and destination for addresses in MATCH_CIDR.
ARGS=( --pnat="$MATCH_CIDR:$HOME_NET_CIDR" --fixcsum --infile="$IN" --outfile="$OUT" )
if [[ "$TO_ETHERNET" == "1" ]]; then
  ARGS+=( --dlt=enet --enet-smac="$ENET_SMAC" --enet-dmac="$ENET_DMAC" )
fi

echo "[*] tcprewrite ${ARGS[*]}"
tcprewrite "${ARGS[@]}"

echo "[+] wrote $OUT"
if command -v tcpdump >/dev/null 2>&1; then
  echo "[*] first rewritten packets (confirm src/dst now sit in $HOME_NET_CIDR):"
  tcpdump -nr "$OUT" 2>/dev/null | head -3 || true
fi
