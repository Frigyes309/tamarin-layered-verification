# Publishing checklist

Copy this file to `PUBLISHING.md` at the repository root when you start preparing the Zenodo
release. From then on, the `hygiene` workflow runs the publication gate (`just hygiene --publish`),
which checks everything a script can check. The items below are the rest. Tick each one and
write the evidence after it: a commit, a file and line, a command and its output, or a link. An
advisor signs the list off by approving the pull request that completes it. `.gitattributes`
keeps this file out of the Zenodo archive.

Filled in on 2026-11-01 by an agent working for Martin, on branch `publish/gate`. Unticked items
wait for Martin or Ferenc; each says what is missing.

## Results

- [x] `just reproduce` regenerates every figure and table in the paper, and `just reproduce --smoke`
      finishes in minutes. Evidence: the repository serves two papers, and the results maps
      (`README.md:38`, `README.md:50`) list every table and figure with data in either. The
      remaining figures of both papers are diagrams with no data. `just reproduce` (`justfile:24`)
      runs the nine runs of `run_all.sh`, compares them with `results/` (`just check`), then runs
      the scaled layer-6 models K = 1, 2, 3, 4, 8 and compares them with `scalability/results/`
      (`just fig-scalability`, `justfile:73`). The Byzantine Clocks paper's scalability section is
      analytic, so nothing runs for it. On 2026-11-01, in the image built from this branch:
      `docker run --rm -u "$(id -u):$(id -g)" -v /tmp/smuk-out:/out tlv-publish reproduce --smoke`
      printed `5 runs match results/` and `1 scaled models match scalability/results/`, exit 0,
      in under a minute after the build. `... tlv-publish fig-scalability --runs 1 1 2 3 4` printed
      `4 scaled models match scalability/results/` (0.9, 6.0, 20.9 and 49.2 s on a Ryzen 9
      7950X3D), exit 0.
      The full `reproduce` (about 20 minutes, 12 GiB for `L5_Session`) was not run by the agent.
- [x] Recipes are named after their outputs, such as `fig-scalability` or `tab-robustness`. Evidence:
      `just --summary` lists `check default fig-scalability hygiene reproduce tab-correctness
      tab-robustness tab-timing`. `timing` stays as an alias of `tab-timing` (`justfile:68`),
      because the earlier README named it.
- [x] The results map has one row per figure and table of the paper, each with its command,
      output path and time on the stated hardware. Evidence: `README.md:38` (Tamarin paper:
      `tab:correctness`, `tab:lv:summary`, `tab:robustness`, `tab:lv:timing`, `fig:lv:scale`,
      `tab:lv:scale-timing`) and `README.md:50` (Byzantine Clocks paper: `tab:correctness`,
      `tab:app:lemmas`, `tab:robustness`, `tab:app:bench`, and the analytic `sec:scalability`).
      Labels were read from both papers' `main` on 2026-11-01. Times are derived from the
      hyperfine means of the paper's laptop (`results/hyperfine/hyperfine.md`,
      `scalability/results/hyperfine-*.md`).
- [ ] Every dependency is pinned in the `Dockerfile` and the lockfiles. Evidence: the base image is
      pinned by digest (`Dockerfile:2`), and Tamarin 1.12.0 and Maude 3.5.1 are release binaries
      checked against their SHA-256 (`Dockerfile:4-7`). Not pinned: `just`, `hyperfine`,
      `graphviz` and the libraries from Ubuntu's archive (`Dockerfile:10`); `apt-get update`
      takes whatever the archive has at build time. None of them affects a verdict or step count,
      but `hyperfine` measures the times. There are no language manifests, so no lockfiles.
      Martin decides whether this is enough.

## Metadata

- [ ] The license was agreed with the advisors: Apache 2.0 for a tool, MIT otherwise. Evidence:
      `LICENSE` is MIT (copyright Ferenc Smuk 2026), committed by Ferenc in fa98195, and
      `.zenodo.json:6` and `CITATION.cff:10` agree. The repository holds results, not a tool, so
      MIT is the guide's default. The agent has no record of the agreement; Martin confirms it by
      approving.
- [ ] `related_identifiers` in `.zenodo.json` lists `isDerivedFrom` for a fork's upstream and
      `isSupplementTo` for each paper with a DOI, and nothing else. Evidence: the field is left
      out. Neither paper has a DOI or a public URL: both are unpublished TDK 2026 papers, and the
      guide (`08-zenodo.tex:14`) says to leave the field out until the identifier is real. The plan
      asks for two `isSupplementTo` entries; they wait for the papers' identifiers. Not a fork.
- [x] A fork keeps the upstream license, names the upstream authors in `.zenodo.json` and says
      in the README what it changed. Write "not a fork" otherwise. Evidence: not a fork
      (`gh api repos/Frigyes309/tamarin-layered-verification --jq .fork` is `false`).
- [x] A tool has the tool README sections, `MAINTAINERS.md` and `SECURITY.md`. Write "results
      only" otherwise. Evidence: results only.

## Before going public

The repository is already public (it was created public), so these items describe its current
state.

- [x] Every history warning of `just hygiene --publish` has been read. The history is not rewritten:
      each warning is either harmless once public or listed here with why it is acceptable. Evidence:
      one history warning, `local-path` in `run_all.sh`: fa98195 set the default
      `TAMARIN` to the Homebrew-on-Linux install path of `tamarin-prover`, and 6bdce1c replaced it with
      `tamarin-prover` from `PATH`. It is the standard Homebrew-on-Linux prefix and names no
      user. The other five warnings are about the tree: no `src/`, `tests/`, `experiments/` (the
      repository keeps its own layout), no DOI badge yet (expected before the first release), and
      `smoke` (CI runs `reproduce --smoke` through the image's `just` entry point,
      `.github/workflows/ci.yml:17`, which the gate's text match does not see).
- [x] Every secret gitleaks ever found has been rotated: the key, token or wallet no longer
      works or holds anything. Evidence: gitleaks found none. GITLEAKS_RESULT
- [x] No link points to a same-year TDK paper. Evidence: the README names both of Ferenc's papers by
      title, because the plan makes this repository the artifact of both, and links neither.
      `git grep -n -i -E 'overleaf|TDK26|tdk\.bme|github\.com/[^/]+/(Scalable|TDK)'` finds nothing
      outside `scripts/hygiene.py` and this line.
- [ ] No AI app or bot is a collaborator or installed app with write access (Settings,
      Collaborators and GitHub Apps). Evidence: collaborators are `Frigyes309` (admin) and
      `BlackLight54` (write), both people (`gh api repos/Frigyes309/tamarin-layered-verification/collaborators`).
      Installed GitHub Apps need admin rights to list; Ferenc checks
      https://github.com/Frigyes309/tamarin-layered-verification/settings/installations.
- [x] A `CLAUDE.md` or `AGENTS.md` that documents the code was renamed, so the archive keeps it.
      Evidence: the repository tracks no agent files (`git ls-files` matches none of `.claude`,
      `CLAUDE.md`, `AGENTS.md`, `.codex`, `.cursor`, `.gemini`).

## Release (the student's steps, after the pull request merges)

- [ ] The repository and its ghcr.io package are public, and an anonymous
      `docker manifest inspect ghcr.io/frigyes309/tamarin-layered-verification:v1.0.0` succeeds. Evidence:
- [ ] Zenodo is enabled for the repository, and release `v1.0.0` is tagged on the commit whose
      results match the paper. Evidence:
- [ ] The Zenodo record's files and metadata are checked, including both supervisors. The
      concept DOI badge in the README resolves. Evidence:
