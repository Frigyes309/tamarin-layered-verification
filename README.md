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

All 29 lemmas of the five theories are verified automatically, with no interactive proof step, and all four controls find their attack trace. The longest run (L5) takes about 2.5 minutes. The per-lemma outcomes and step counts are in [`results/SUMMARY.txt`](results/SUMMARY.txt).

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

