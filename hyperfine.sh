#!/usr/bin/env bash
# Hyperfine over the nine runs of run_all.sh (same run table). Needs a Tamarin
# release binary from https://github.com/tamarin-prover/tamarin-prover/releases
# (TAMARIN or --tamarin, default: tamarin-prover on PATH) and Maude, since the
# release binary does not bundle Maude. Maude on PATH is used as is; without
# it, the script takes Maude from nixpkgs.
#
#   ./hyperfine.sh [--dry-run] [--runs N] [--repo DIR] [--out DIR] [--tamarin BIN]
#
# Writes <out>/hyperfine.{json,md}, <out>/meta.txt and <out>/logs/<run>.log
# (stdout of the last timed run of each command, for the verdict check).
set -euo pipefail

RUNS=3
DRY=0
REPO="$(cd "$(dirname "$0")" && pwd)"
OUT="$REPO/results/hyperfine"
TAMARIN="${TAMARIN:-$(command -v tamarin-prover || true)}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --runs) RUNS="$2"; shift ;;
    --repo) REPO="$2"; shift ;;
    --out) OUT="$2"; shift ;;
    --tamarin) TAMARIN="$2"; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

command -v hyperfine >/dev/null || { echo "hyperfine not on PATH" >&2; exit 1; }
if command -v maude >/dev/null; then
  WITH_MAUDE=()
elif command -v nix >/dev/null; then
  WITH_MAUDE=(nix shell nixpkgs#maude -c)
else
  echo "neither maude nor nix on PATH" >&2; exit 1
fi
[ -x "$TAMARIN" ] || { echo "$TAMARIN is not executable; pass --tamarin" >&2; exit 1; }
[ -f "$REPO/run_all.sh" ] || { echo "$REPO is not this repository" >&2; exit 1; }

# name | theory | flags (same table as run_all.sh)
TABLE=(
  "L123_Network|L123_Network.spthy|--prove"
  "L123_Network_TWO_BYZANTINE|L123_Network.spthy|-D=TWO_BYZANTINE --prove=conflicting_qc_attack"
  "L4_Transport|L4_Transport.spthy|--prove"
  "L4_Transport_UNBOUND_INPUTS|L4_Transport.spthy|-D=UNBOUND_INPUTS --prove=invalid_tx_no_valid_zkp"
  "L5_Session|L5_Session.spthy|--prove"
  "L6_Presentation|L6_Presentation.spthy|--prove"
  "L6_Presentation_SEPARATE_SLOTS|L6_Presentation.spthy|-D=SEPARATE_SLOTS --prove=gateway_exclusivity --prove=no_fallback_via_event_gate"
  "L7_Application|L7_Application.spthy|--prove"
  "L7_Application_NO_CAS|L7_Application.spthy|-D=NO_CAS --prove=no_state_bifurcation --prove=no_double_existence"
)

ARGS=(--runs "$RUNS" --warmup 0 --ignore-failure --shell=bash --export-json "$OUT/hyperfine.json" --export-markdown "$OUT/hyperfine.md")
for row in "${TABLE[@]}"; do
  IFS='|' read -r name theory flags <<< "$row"
  ARGS+=(--command-name "$name" "cd $(printf %q "$REPO") && $(printf %q "$TAMARIN") $flags $theory --output=$(printf %q "$OUT/proofs/$name.proof.spthy") > $(printf %q "$OUT/logs/$name.log") 2>&1")
done

if [ "$DRY" = 1 ]; then
  printf '%s ' ${WITH_MAUDE[@]+"${WITH_MAUDE[@]}"} hyperfine; printf '%q ' "${ARGS[@]}"; echo
  exit 0
fi

mkdir -p "$OUT/logs" "$OUT/proofs"
{
  echo "date: $(date -u +%FT%TZ)"
  echo "host: $(hostname), $(nproc) threads, $(lscpu | sed -n 's/^Model name: *//p')"
  ${WITH_MAUDE[@]+"${WITH_MAUDE[@]}"} sh -c "echo maude: \$(maude --version); $(printf %q "$TAMARIN") --version 2>&1 | grep -m1 tamarin-prover" || true
  echo "repo: $(git -C "$REPO" rev-parse HEAD)"
  echo "runs per command: $RUNS"
} > "$OUT/meta.txt"

${WITH_MAUDE[@]+"${WITH_MAUDE[@]}"} hyperfine "${ARGS[@]}"

# Verdicts of the last timed run of each command.
for row in "${TABLE[@]}"; do
  IFS='|' read -r name _ _ <<< "$row"
  echo "== $name"
  sed -n '/summary of summaries/,$p' "$OUT/logs/$name.log" | grep -E '^  [A-Za-z0-9_]+ \((all-traces|exists-trace)\)' || echo "  NO SUMMARY (see $OUT/logs/$name.log)"
done | tee "$OUT/verdicts.txt"
echo "wrote $OUT/hyperfine.md and $OUT/verdicts.txt"
