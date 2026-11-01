#!/usr/bin/env bash
# Times the scaled layer-6 theories (generate.py) with hyperfine and checks the
# verdict of every lemma in the last timed run. Needs hyperfine, tamarin-prover
# and maude on PATH.
#
#   ./run.sh [--runs N] [K ...]      (default: 3 runs, K = 1 2 3 4)
#
# TIMEOUT (default 1800 s) limits the time and HEAP (default 8G) the memory of
# each Tamarin run. Writes results/hyperfine-<sizes>.{json,md},
# results/verdicts-<sizes>.txt and results/logs/<theory>.log, where <sizes> is
# for example 1-2-3-4; only the .md and the verdicts are committed.
set -euo pipefail

RUNS=3
if [ "${1:-}" = "--runs" ]; then RUNS="$2"; shift 2; fi
SIZES=("$@"); [ ${#SIZES[@]} -eq 0 ] && SIZES=(1 2 3 4)

HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/results"
TAMARIN="$(command -v tamarin-prover)"
TIMEOUT="${TIMEOUT:-1800}"
HEAP="${HEAP:-8G}"
TAG="$(IFS=-; echo "${SIZES[*]}")"
mkdir -p "$OUT/logs" "$OUT/proofs"

ARGS=(--runs "$RUNS" --warmup 0 --ignore-failure --shell=bash
      --export-json "$OUT/hyperfine-$TAG.json" --export-markdown "$OUT/hyperfine-$TAG.md")
for k in "${SIZES[@]}"; do
  name="L6_Scaled_x$k"
  ARGS+=(--command-name "$name" "cd $(printf %q "$HERE") && timeout $TIMEOUT $(printf %q "$TAMARIN") +RTS -M$HEAP -RTS --prove $name.spthy --output=$(printf %q "$OUT/proofs/$name.proof.spthy") > $(printf %q "$OUT/logs/$name.log") 2>&1")
done

hyperfine "${ARGS[@]}"

for k in "${SIZES[@]}"; do
  name="L6_Scaled_x$k"
  echo "== $name"
  sed -n '/summary of summaries/,$p' "$OUT/logs/$name.log" | grep -E '^  [A-Za-z0-9_]+ \((all-traces|exists-trace)\)' || echo "  NO SUMMARY, timeout or heap limit? (see $OUT/logs/$name.log)"
done | tee "$OUT/verdicts-$TAG.txt"
