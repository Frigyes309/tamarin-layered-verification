---
role: code
description: Authoritative Tamarin models and results for Ferenc Smuk's TDK 2026 paper.
repository: https://github.com/Frigyes309/tamarin-layered-verification
---

# Layered verification in Tamarin

Tamarin models for the paper **Bottom-Up Formal Verification of Temporal Constraints in Self-Orchestrated Business Processes** (Ferenc Smuk, BME VIK TDK 2026; advisors: Martin Farkas, Dr. Imre Kocsis).

The paper verifies self-orchestrated BPMN collaborations, where no trusted orchestrator exists, against a combined Dolev–Yao and Byzantine coalition adversary. Instead of one large model, it splits the system into an OSI-style stack and gives each layer its own Tamarin theory. The lemmas proven on one layer become the assumptions of the layer above, which keeps each state space small. Metric deadlines are encoded as logical ordering facts over threshold-signed Verifiable Epistemic Beacons, so the untimed prover can show that no malicious party can backdate or forward-date a process event.

The paper cites this repository as `tdkrepo`. Its appendix holds the proofs that go beyond Tamarin.

## Theories

| File                                             | Layer                                      | Main properties                                                                                                                       |
| ------------------------------------------------ | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| [`L123_Network.spthy`](L123_Network.spthy)       | 1–3: physical, data link, network          | transaction authenticity; every quorum certificate contains an honest vote; no two conflicting QCs in a view (split-brain prevention) |
| [`L4_Transport.spthy`](L4_Transport.spthy)       | 4: transport (Local VDR → Global VDR)      | an invalid transaction gets no valid folding proof; only certified roots reach the Global VDR                                         |
| [`L5_Session.spthy`](L5_Session.spthy)           | 5: session (beacons, Lamport matrix)       | beacon unpredictability; monotone ledger and Lamport matrix; no backdating, no forward-dating, bounded claim window                   |
| [`L6_Presentation.spthy`](L6_Presentation.spthy) | 6: presentation (BPMN event-based gateway) | gateway exclusivity; a timer fires only after its deadline; a message wins only before it                                             |
| [`L7_Application.spthy`](L7_Application.spthy)   | 7: application (VC chain)                  | no state bifurcation; no double existence; history integrity                                                                          |

Each theory also has an executability lemma that shows the honest protocol can run to completion.

## Negative controls

Each control removes one defence with a `-D` flag, and Tamarin then finds an attack. This shows that the lemmas depend on that defence and are not vacuously true.

| Flag             | Theory | What it removes                                                      | Result                       |
| ---------------- | ------ | -------------------------------------------------------------------- | ---------------------------- |
| `TWO_BYZANTINE`  | L1–3   | allows two corrupted nodes out of four                               | conflicting QCs              |
| `UNBOUND_INPUTS` | L4     | does not bind the proof to its inputs                                | invalid transaction accepted |
| `SEPARATE_SLOTS` | L6     | gives the gateway branches separate slots                            | both branches fire           |
| `NO_CAS`         | L7     | splits the compare-and-swap into a separate check and write (TOCTOU) | state bifurcation            |

## Results

All 29 lemmas of the five theories are verified automatically, with no interactive proof step, and all four controls find their attack trace. On the paper's laptop the whole suite takes about 5 minutes, and the longest run (L5) about 2.2 minutes (see [Timing](#timing)). The per-lemma outcomes and step counts are in [`results/SUMMARY.txt`](results/SUMMARY.txt).

## Running

The paper used Tamarin 1.12.0 and Maude 3.5.1 on Ubuntu (WSL 2).

```sh
TAMARIN=$(command -v tamarin-prover) bash run_all.sh
```

`run_all.sh` runs every theory and the four negative controls, and writes one summary per run into `results/` plus `results/SUMMARY.txt`. `TIMEOUT` (default 1800 s) limits each run. The full proofs go to `results/*.proof.spthy`, which git does not track.

To open a single theory in the interactive GUI:

```sh
tamarin-prover interactive L5_Session.spthy
```

## Reproduce and check

Build the runtime image locally, then reproduce all five theories and four negative controls:

```sh
docker build -t tamarin-layered-verification .
mkdir -p out
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD/out:/out" tamarin-layered-verification reproduce
```

The image includes Tamarin 1.12.0, Maude 3.5.1 and `just`. It writes proofs and summaries to `out/` and checks every lemma verdict and proof size against the committed `results/`, ignoring wall-clock times. Missing summaries or different verdicts or step counts fail the check. The committed models and results are never overwritten by these recipes.

Add `--smoke` after `reproduce` to run the five short cases used in CI. With the dependencies on `PATH`, `just reproduce` runs the full suite locally and `just check` repeats its comparison. `just tab-correctness` selects the five layer theories and the `NO_CAS` control; `just tab-robustness` selects all four negative controls. `just timing` invokes the existing hyperfine script and needs its additional dependencies. The devcontainer builds the same Dockerfile.

`run_all.sh [RUN...]` accepts run names from its table. `TAMARIN` defaults to `tamarin-prover` on `PATH`, `TIMEOUT` to 1800 seconds, and `OUT` to `results/` when invoked directly or `out/` through `just`.

Publishing a GitHub release triggers the container workflow, which publishes `ghcr.io/frigyes309/tamarin-layered-verification:<release-tag>`. Until a release image is available, use the local build above. `.zenodo.json` supplies archive metadata, but Zenodo integration and DOI assignment are separate publication steps.

## Citation and license

Citation metadata is in [`CITATION.cff`](CITATION.cff). The code is licensed under MIT; see [`LICENSE`](LICENSE).

## Timing

`./hyperfine.sh` times the same nine runs with hyperfine (3 runs each, no warmup) and checks the verdict of every lemma in the last timed run. It needs `hyperfine`, a `tamarin-prover` binary and Maude, either on `PATH` or through nix. It writes into `results/hyperfine/` (or `--out DIR`); of its output only the table [`results/hyperfine/hyperfine.md`](results/hyperfine/hyperfine.md) is committed.

Measured on the laptop the paper reports: Intel Core i9-13900HX (32 threads), 64 GB, Ubuntu 26.04 in WSL 2, Tamarin 1.12.0, Maude 3.5.1, hyperfine 2.0.0.

| Run | Wall time [s], mean ± σ | Peak memory |
|---|---:|---:|
| `L123_Network` | 52.6 ± 0.6 | 4.7 GiB |
| `L123_Network_TWO_BYZANTINE` | 3.3 ± 0.1 | 0.2 GiB |
| `L4_Transport` | 1.9 ± 0.0 | 0.2 GiB |
| `L4_Transport_UNBOUND_INPUTS` | 2.3 ± 0.1 | 0.2 GiB |
| `L5_Session` | 134.3 ± 3.3 | 11.9 GiB |
| `L6_Presentation` | 52.4 ± 1.4 | 1.4 GiB |
| `L6_Presentation_SEPARATE_SLOTS` | 6.8 ± 0.1 | 0.4 GiB |
| `L7_Application` | 5.1 ± 0.2 | 0.3 GiB |
| `L7_Application_NO_CAS` | 46.8 ± 1.6 | 2.4 GiB |
| **Full suite** | **≈ 5 min** | |

The times match the single runs in `results/SUMMARY.txt`, and every lemma gives the same verdict and step count as there.

