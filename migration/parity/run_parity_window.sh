#!/usr/bin/env bash
# =============================================================================
# run_parity_window.sh — Phase 2 (Gate 2) parity activity generator  [#171/P2.5]
#
# Runs the FIXED parity activity set on the monitored segment so BOTH Security
# Onion and the legacy ELK stack observe the same traffic, then prints the exact
# UTC window to query in each. Reuses the sims in tests/anomaly_simulation/ —
# it does not reinvent the activity; it pins the target to the monitored
# segment, times the window, and writes a results file.
#
# It does NOT query Elasticsearch: SO grid access is deferred to Phase 4, and the
# two stacks use different index/ECS schemas. Count events per activity in each
# stack for the printed window and record them in the results file and in
# docs/migration/evidence/phase-2.md (A5).
#
# Ownership: [HUMAN], run from a host on the monitored segment (runbook Phase 2).
# =============================================================================

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

# --- config (override via env or a local .env) -------------------------------
[[ -f .env ]] && set -a && source .env && set +a

SIMS_DIR="${SIMS_DIR:-$HERE/../../tests/anomaly_simulation}"
RESULTS_DIR="${RESULTS_DIR:-$HERE/results}"
PARITY_ACTIVITIES="${PARITY_ACTIVITIES:-portscan ssh}"
PARITY_TARGET="${PARITY_TARGET:-}"

# --- guards ------------------------------------------------------------------
if [[ -z "$PARITY_TARGET" ]]; then
  cat >&2 <<'MSG'
[ERROR] PARITY_TARGET is not set.
        Set it to a host ON the monitored segment (e.g. a lab box on
        10.18.81.0/24) so the traffic crosses the monitor NIC. Example:
          PARITY_TARGET=10.18.81.50 ./run_parity_window.sh
MSG
  exit 2
fi

case "$PARITY_TARGET" in
  127.*|localhost|::1)
    cat >&2 <<'MSG'
[ERROR] PARITY_TARGET points at localhost — loopback traffic never crosses the
        monitor NIC, so Security Onion's sensors will see nothing. Target a
        different host on the monitored segment.
MSG
    exit 2
    ;;
esac

if [[ ! -d "$SIMS_DIR" ]]; then
  echo "[ERROR] SIMS_DIR not found: $SIMS_DIR" >&2
  exit 2
fi

mkdir -p "$RESULTS_DIR"

# --- map activity name -> reused sim script ----------------------------------
declare -A SIM_FOR=(
  [portscan]="sim_portscan.sh"
  [ssh]="sim_brute_ssh.sh"
  [malware]="sim_malware_download.sh"
)

# --- run the window ----------------------------------------------------------
WINDOW_START="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================================"
echo " Phase 2 parity window"
echo " target:      $PARITY_TARGET (must be on the monitored segment)"
echo " activities:  $PARITY_ACTIVITIES"
echo " start (UTC): $WINDOW_START"
echo "============================================================"

for act in $PARITY_ACTIVITIES; do
  sim="${SIM_FOR[$act]:-}"
  if [[ -z "$sim" ]]; then
    echo "[WARN] unknown activity '$act' — skipping (known: ${!SIM_FOR[*]})" >&2
    continue
  fi
  if [[ ! -f "$SIMS_DIR/$sim" ]]; then
    echo "[WARN] sim not found: $SIMS_DIR/$sim — skipping '$act'" >&2
    continue
  fi
  echo
  echo "--- activity: $act ($sim) ---"
  # Point the reused sim at the parity target; allow it to fail (missing
  # nmap/sshpass, or the expected SSH auth failures) without aborting the window.
  if ! TARGET_HOST="$PARITY_TARGET" bash "$SIMS_DIR/$sim"; then
    echo "[WARN] '$act' sim exited non-zero (missing prereq or expected auth failure)" >&2
  fi
done

WINDOW_END="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo
echo "============================================================"
echo " window complete — end (UTC): $WINDOW_END"
echo "============================================================"

# --- emit a results file from the template -----------------------------------
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$RESULTS_DIR/parity-$STAMP.md"
if [[ -f parity-results-template.md ]]; then
  sed -e "s|<WINDOW_START>|$WINDOW_START|g" \
      -e "s|<WINDOW_END>|$WINDOW_END|g" \
      -e "s|<TARGET>|$PARITY_TARGET|g" \
      -e "s|<ACTIVITIES>|$PARITY_ACTIVITIES|g" \
      parity-results-template.md > "$OUT"
  echo "[+] results file written: $OUT"
else
  echo "[WARN] parity-results-template.md missing; record the window manually" >&2
fi

cat <<MSG

Next (A5 / #171):
  1. Count events for the window
       $WINDOW_START .. $WINDOW_END
     in BOTH stacks (old ELK must stay live during this):
       - Legacy ELK: index logstash-security-* (cf. tests/anomaly_simulation/verify_detections.py)
       - Security Onion: SOC Hunt / Alerts, same window, by event.module:zeek / event.module:suricata
  2. Fill $OUT and copy the table into docs/migration/evidence/phase-2.md (A5).
  3. Confirm SO >= ELK for every activity.
MSG
