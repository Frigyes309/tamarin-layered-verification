#!/usr/bin/env bash
# Runs every layer theory and every negative control, and writes a short
# summary per run into $OUT (default results/).
#
#   ./run_all.sh [RUN...]
#
# With run names as arguments, only those rows of the table run. TAMARIN names
# the prover binary (default: tamarin-prover on PATH). The full proofs are
# written to $OUT/*.proof.spthy (not tracked by git).

set -uo pipefail
cd "$(dirname "$0")" || exit 1

TAMARIN="${TAMARIN:-tamarin-prover}"
TIMEOUT="${TIMEOUT:-1800}"
OUT="${OUT:-results}"
command -v "$TAMARIN" >/dev/null || { echo "$TAMARIN not found; set TAMARIN to the tamarin-prover binary" >&2; exit 1; }
mkdir -p "$OUT" || exit 1

# name | theory | extra flags | expected outcome of the run
RUNS=(
  "L123_Network|L123_Network.spthy||all lemmas verified"
  "L123_Network_TWO_BYZANTINE|L123_Network.spthy|-D=TWO_BYZANTINE --prove=conflicting_qc_attack|attack trace found"
  "L4_Transport|L4_Transport.spthy||all lemmas verified"
  "L4_Transport_UNBOUND_INPUTS|L4_Transport.spthy|-D=UNBOUND_INPUTS --prove=invalid_tx_no_valid_zkp|lemma falsified"
  "L5_Session|L5_Session.spthy||all lemmas verified"
  "L6_Presentation|L6_Presentation.spthy||all lemmas verified"
  "L6_Presentation_SEPARATE_SLOTS|L6_Presentation.spthy|-D=SEPARATE_SLOTS --prove=gateway_exclusivity --prove=no_fallback_via_event_gate|lemmas falsified"
  "L7_Application|L7_Application.spthy||all lemmas verified"
  "L7_Application_NO_CAS|L7_Application.spthy|-D=NO_CAS --prove=no_state_bifurcation --prove=no_double_existence|lemmas falsified"
)

for want in "$@"; do
  printf '%s\n' "${RUNS[@]}" | cut -d '|' -f 1 | grep -Fxq -- "$want" || { echo "unknown run: $want" >&2; exit 2; }
done

: > "$OUT/SUMMARY.txt" || exit 1
failed=0
for run in "${RUNS[@]}"; do
  IFS='|' read -r name theory flags expected <<< "$run"
  if [ $# -gt 0 ] && [[ " $* " != *" $name "* ]]; then continue; fi
  [ -z "$flags" ] && flags="--prove"
  echo "== $name ($expected)" | tee -a "$OUT/SUMMARY.txt"
  start=$(date +%s)
  # shellcheck disable=SC2086
  timeout "$TIMEOUT" "$TAMARIN" $flags "$theory" \
      --output="$OUT/$name.proof.spthy" > "$OUT/$name.log" 2>&1
  status=$?
  end=$(date +%s)
  if [ "$status" -ne 0 ]; then
    echo "prover failed for $name (exit $status); see $OUT/$name.log" >&2
    failed=1
  fi
  sed -n '/summary of summaries/,$p' "$OUT/$name.log" \
    | grep -E '^  [A-Za-z0-9_]+ \((all-traces|exists-trace)\)' \
    | grep -v 'analysis incomplete (1 steps)' \
    | tee "$OUT/$name.txt" | tee -a "$OUT/SUMMARY.txt" || failed=1
  [ $status -eq 124 ] && echo "  TIMEOUT after ${TIMEOUT}s" | tee -a "$OUT/SUMMARY.txt"
  echo "  wall-clock time: $((end - start)) s" | tee -a "$OUT/$name.txt" | tee -a "$OUT/SUMMARY.txt"
  if [ "$status" -eq 0 ]; then rm -f "$OUT/$name.log"; fi
done

exit "$failed"
