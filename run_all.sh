#!/usr/bin/env bash
# Runs every layer theory and every negative control, and writes a short
# summary per run into results/. Usage (from WSL):  ./run_all.sh
# The full proofs are written to results/*.proof.spthy (not tracked by git).

set -u
cd "$(dirname "$0")"

TAMARIN="${TAMARIN:-/home/linuxbrew/.linuxbrew/bin/tamarin-prover}"
TIMEOUT="${TIMEOUT:-1800}"
mkdir -p results

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

: > results/SUMMARY.txt
for run in "${RUNS[@]}"; do
  IFS='|' read -r name theory flags expected <<< "$run"
  [ -z "$flags" ] && flags="--prove"
  echo "== $name ($expected)" | tee -a results/SUMMARY.txt
  start=$(date +%s)
  # shellcheck disable=SC2086
  timeout "$TIMEOUT" "$TAMARIN" $flags "$theory" \
      --output="results/$name.proof.spthy" > "results/$name.log" 2>&1
  status=$?
  end=$(date +%s)
  sed -n '/summary of summaries/,$p' "results/$name.log" \
    | grep -E '^  [A-Za-z0-9_]+ \((all-traces|exists-trace)\)' \
    | grep -v 'analysis incomplete (1 steps)' \
    | tee "results/$name.txt" | tee -a results/SUMMARY.txt
  [ $status -eq 124 ] && echo "  TIMEOUT after ${TIMEOUT}s" | tee -a results/SUMMARY.txt
  echo "  wall-clock time: $((end - start)) s" | tee -a "results/$name.txt" | tee -a results/SUMMARY.txt
  rm -f "results/$name.log"
done
