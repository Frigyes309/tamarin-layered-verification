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

# Every run of the paper, then the verdict check. `just reproduce --smoke` runs only the runs under 10 s.
reproduce *flags:
    case "{{flags}}" in "") OUT="{{out}}" bash run_all.sh; OUT="{{out}}" just check ;; --smoke) OUT="{{out}}" bash run_all.sh {{smoke}}; OUT="{{out}}" just check {{smoke}} ;; *) echo "usage: just reproduce [--smoke]" >&2; exit 2 ;; esac

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

# Time the nine runs with hyperfine (needs hyperfine and Maude on PATH or through nix; see hyperfine.sh).
timing *args:
    bash hyperfine.sh {{args}}
