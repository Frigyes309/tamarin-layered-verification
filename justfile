# The recipes the README and CI run. The run table itself lives in run_all.sh;
# these recipes only pick rows of it. Results go to $OUT (default out/), and
# `check` compares their lemma verdicts with the committed record in results/.

set shell := ["bash", "-euo", "pipefail", "-c"]

out := env("OUT", "out")

# The correctness table of the paper (tab:correctness): the five layer theories and the TOCTOU attack.
correctness := "L123_Network L4_Transport L5_Session L6_Presentation L7_Application L7_Application_NO_CAS"

# The robustness table of the paper (tab:robustness): the four negative controls.
robustness := "L123_Network_TWO_BYZANTINE L4_Transport_UNBOUND_INPUTS L6_Presentation_SEPARATE_SLOTS L7_Application_NO_CAS"

# The runs under 10 s, for CI and a quick local check.
smoke := "L123_Network_TWO_BYZANTINE L4_Transport L4_Transport_UNBOUND_INPUTS L6_Presentation_SEPARATE_SLOTS L7_Application"

default:
    @just --list

# Every table and figure of both papers: the nine runs, then the scaled layer-6 models with
# K = 1, 2, 3, 4 and 8 (one timed run each), each followed by its verdict check. About 20 minutes,
# of which the 8x model takes 13. `just reproduce --smoke` runs the five runs under 10 s and K = 1.
reproduce *flags:
    case "{{flags}}" in "") OUT="{{out}}" bash run_all.sh; OUT="{{out}}" just check; OUT="{{out}}" just fig-scalability --runs 1 1 2 3 4 8 ;; --smoke) OUT="{{out}}" bash run_all.sh {{smoke}}; OUT="{{out}}" just check {{smoke}}; OUT="{{out}}" just fig-scalability --runs 1 1 ;; *) echo "usage: just reproduce [--smoke]" >&2; exit 2 ;; esac

# The correctness table: base theories and the known attack.
tab-correctness:
    OUT="{{out}}" bash run_all.sh {{correctness}}
    OUT="{{out}}" just check {{correctness}}

# The robustness table: one assumption or honest check dropped at a time.
tab-robustness:
    OUT="{{out}}" bash run_all.sh {{robustness}}
    OUT="{{out}}" just check {{robustness}}

# Compare the lemma verdicts and proof sizes in $OUT with results/, ignoring wall-clock times.
check *runs:
    #!/usr/bin/env bash
    set -euo pipefail
    files=(results/*.txt)
    selected=( {{runs}} )
    if [ "${#selected[@]}" -gt 0 ]; then
      files=()
      for name in "${selected[@]}"; do files+=("results/$name.txt"); done
    fi
    n=0; bad=0
    for reference in "${files[@]}"; do
      name=$(basename "$reference")
      [ "$name" = SUMMARY.txt ] && continue
      n=$((n + 1))
      if [ ! -f "$reference" ] || [ ! -f "{{out}}/$name" ]; then
        echo "missing reference or output: $name" >&2; bad=1; continue
      fi
      if ! diff <(grep -v 'wall-clock time' "$reference") <(grep -v 'wall-clock time' "{{out}}/$name"); then
        echo "verdicts or proof sizes differ: $name" >&2; bad=1
      fi
    done
    [ "$n" -gt 0 ] || { echo "no run summaries" >&2; exit 1; }
    [ "$bad" = 0 ] || exit 1
    echo "$n runs match results/"

# The running-time table (Tamarin paper tab:lv:timing, Byzantine Clocks paper tab:app:bench): the nine
# runs timed with hyperfine, 3 runs each (needs hyperfine and Maude on PATH or through nix; see hyperfine.sh).
tab-timing *args:
    bash hyperfine.sh {{args}}

alias timing := tab-timing

# The scalability figure and table (Tamarin paper fig:lv:scale, tab:lv:scale-timing): the scaled layer-6
# models timed with hyperfine (default 3 runs, K = 1 2 3 4), then their verdicts and proof sizes
# compared with scalability/results/. Takes the arguments of scalability/run.sh: [--runs N] [K ...].
fig-scalability *args:
    #!/usr/bin/env bash
    set -euo pipefail
    export OUT="{{out}}"
    bash scalability/run.sh {{args}}
    set -- {{args}}
    [ "${1:-}" = "--runs" ] && shift 2
    sizes=("$@"); [ ${#sizes[@]} -gt 0 ] || sizes=(1 2 3 4)
    block() { awk -v h="== L6_Scaled_x$1" '$0 == h {p = 1; print; next} /^== / {p = 0} p' "${@:2}"; }
    bad=0
    for k in "${sizes[@]}"; do
      expected=$(block "$k" scalability/results/verdicts-*.txt)
      actual=$(block "$k" "$OUT"/scalability/verdicts-*.txt)
      if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
        echo "verdicts or proof sizes differ: L6_Scaled_x$k" >&2
        diff <(echo "$expected") <(echo "$actual") >&2 || true
        bad=1
      fi
    done
    [ "$bad" = 0 ] || exit 1
    echo "${#sizes[@]} scaled models match scalability/results/"

# What must not reach a public repository: private links, local paths, paper sources, agent
# commit identities and agent files in the archive. Pass --strict before the repository goes public.
hygiene *flags:
    python3 scripts/hygiene.py {{flags}}
