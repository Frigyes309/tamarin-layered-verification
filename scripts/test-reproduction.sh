#!/usr/bin/env bash
# Check failure handling without running the prover.
set -euo pipefail
cd "$(dirname "$0")/.."
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
export OUT="$fixture/out"
mkdir -p "$OUT"
cp results/*.txt "$OUT/"
expect_failure() {
  if "$@" > "$fixture/check.log" 2>&1; then
    echo "unexpected success: $*" >&2
    exit 1
  fi
}
just check
rm "$OUT/L4_Transport.txt"
expect_failure just check
cp results/L4_Transport.txt "$OUT/"
sed -i 's/verified/falsified/g' "$OUT/L4_Transport.txt"
expect_failure just check
cp results/L4_Transport.txt "$OUT/"
just check L4_Transport
expect_failure just check NOT_A_RUN
expect_failure just reproduce --unknown
expect_failure env TAMARIN=true bash run_all.sh NOT_A_RUN
expect_failure env TAMARIN=false bash run_all.sh L4_Transport
expect_failure env TAMARIN=true bash run_all.sh L4_Transport
printf 'Reproduction checker and runner failure tests passed.\n'
