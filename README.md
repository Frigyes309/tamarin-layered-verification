---
role: code
description: Authoritative Tamarin models and results for Ferenc Smuk's TDK 2026 paper.
repository: https://github.com/Frigyes309/tamarin-layered-verification
---

# Layered verification in Tamarin

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.TODO.svg)](https://doi.org/10.5281/zenodo.TODO)

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

The paper used Tamarin 1.12.0 and Maude 3.5.1 on Ubuntu (WSL 2). Without a local installation, use the [Docker image](#docker).

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

## Scalability

[`scalability/`](scalability/) shows that the layer-6 proofs carry over to larger business processes (Section 5.11 of the paper). It holds BPMN models 1, 2, 3, 4 and 8 times the size of the webshop process of `L6_Presentation`, the generator that writes them and the benchmark of their proofs.

**Process.** One stage is the process of `L6_Presentation`: `OrderCreated` → parallel split → `NotifyWarehouse` and an event-based gateway with the alternatives `message`, `timer` and `signal`. The model of size K chains K stages; the `message` alternative of a stage leads through a `Continue` task to the next stage. With the start event, the model has 8K nodes.

**Encoding.** `Instance_Start` draws a fresh identifier for every node of a new instance and emits the structure of the process as persistent facts over these identifiers (`!Next` for a sequence flow, `!Split` for a parallel split, `!Alt` for a gateway alternative). A token is `Token(~node)`. The four rules are the same for every size; only the facts of `Instance_Start` grow with the process. Deadlines are left out, since the timing lemmas are proven in `L6_Presentation` and do not depend on the size of the process.

**Lemmas.**

| Lemma | Statement |
|---|---|
| `executable` | a token reaches the last node of the chain (exists-trace) |
| `one_token_per_node` | a token enters every node at most once |
| `admissible_only` | only transitions of the BPMN model take effect |
| `gateway_exclusivity` | at every gateway exactly one alternative takes effect |

`one_token_per_node` is proven by induction (`[use_induction]`). Without it the proof grows quadratically, and the 4× model does not finish within 5 minutes.

**Results.** All lemmas are verified for every size. Same laptop and versions as in [Timing](#timing); mean ± σ of 3 runs.

| | 1× | 2× | 3× | 4× | 8× |
|---|---:|---:|---:|---:|---:|
| BPMN nodes | 8 | 16 | 24 | 32 | 64 |
| Transitions | 7 | 15 | 23 | 31 | 63 |
| Parallel splits / gateways | 1 / 1 | 2 / 2 | 3 / 3 | 4 / 4 | 8 / 8 |
| Tamarin rules | 4 | 4 | 4 | 4 | 4 |
| `executable` (steps) | 8 | 13 | 18 | 23 | 43 |
| `one_token_per_node` (steps) | 137 | 265 | 393 | 521 | 1033 |
| `admissible_only` (steps) | 13 | 21 | 29 | 37 | 69 |
| `gateway_exclusivity` (steps) | 60 | 114 | 168 | 222 | 438 |
| **Wall time** | 1.4 ± 0.1 s | 9.8 ± 0.6 s | 31.5 ± 1.3 s | 75.6 ± 2.7 s | 757.5 ± 11.6 s |
| **Peak memory** | 0.17 GiB | 0.27 GiB | 0.37 GiB | 0.48 GiB | 1.02 GiB |

The number of proof steps grows exactly linearly, by the same amount per stage for every lemma. The wall time grows faster, because every step works on a larger constraint system.

| File | Content |
|---|---|
| [`generate.py`](scalability/generate.py) | writes `L6_Scaled_x<K>.spthy`; `python scalability/generate.py [K ...]`, default K = 1 2 3 4 |
| `L6_Scaled_x{1,2,3,4,8}.spthy` | the generated models |
| [`run.sh`](scalability/run.sh) | times the models with hyperfine and checks every verdict; `bash scalability/run.sh [--runs N] [K ...]` |
| [`results/`](scalability/results/) | `hyperfine-<sizes>.md` (times) and `verdicts-<sizes>.txt` (lemmas and steps) |

`run.sh` limits every Tamarin run to `TIMEOUT` seconds (default 1800) and `HEAP` of memory (default `8G`).

## Docker

The image contains Tamarin 1.12.0, Maude 3.5.1, hyperfine and this repository, so nothing else has to be installed.

```sh
docker build -t tamarin-layered .

# All theories and negative controls (run_all.sh); results land in ./results
docker run --rm -v "$PWD/results:/work/results" tamarin-layered

# Scalability benchmark, 1 run per size
docker run --rm -v "$PWD/scalability/results:/work/scalability/results" tamarin-layered \
  bash scalability/run.sh --runs 1

# One theory
docker run --rm tamarin-layered tamarin-prover --prove L6_Presentation.spthy

# Interactive GUI at http://localhost:3001
docker run --rm -p 3001:3001 tamarin-layered tamarin-prover interactive --interface='*4' .
```

`L5_Session` needs about 12 GiB of memory, so the memory limit of Docker (Docker Desktop: Settings → Resources) has to allow it.

## What does not reproduce

The lemma verdicts and proof step counts reproduce exactly: `just check` compares them with [`results/`](results/) and fails on any difference.

Wall-clock times do not, because they depend on the machine and on the Tamarin and Maude builds, so `just check` ignores them. The times in the paper (48, 2, 141, 63 and 6 s for the five theories) are the single runs in [`results/SUMMARY.txt`](results/SUMMARY.txt), which does not record the Tamarin version or the machine. The hyperfine means under [Timing](#timing), on the paper's laptop with Tamarin 1.12.0 and Maude 3.5.1, are 52.6, 1.9, 134.3, 52.4 and 5.1 s. Expect different times on other hardware.

## Results tag

The verdicts, step counts and times in the paper are the committed [`results/`](results/) of tag `v1.0.0`, Zenodo version TODO. Later versions change the packaging, never the results.

## Cite

Citation metadata is in [`CITATION.cff`](CITATION.cff). As BibTeX, with the concept DOI:

```bibtex
@software{smuk2026tamarin,
  author    = {Smuk, Ferenc},
  title     = {Tamarin theories and results for: Bottom-Up Formal Verification Of Temporal Constraints In Self-Orchestrated Business Processes},
  year      = {2026},
  version   = {v1.0.0},
  publisher = {Zenodo},
  doi       = {10.5281/zenodo.TODO},
  url       = {https://github.com/Frigyes309/tamarin-layered-verification}
}
```

## License

MIT, see [`LICENSE`](LICENSE).
