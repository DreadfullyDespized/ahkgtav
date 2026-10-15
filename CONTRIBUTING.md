# Contributing to ahkgtav

**Repo label: TEST** — verified work merges to `master`; Dread exercises what lands there. Fleet registry: skill "Repo registry (PROD vs TEST)".

What these scripts are for and how to run them on the gaming PC: [README.md](README.md). Agent outline, landmines, and the exact local proof commands: [AGENTS.md](AGENTS.md).

**Owner seat:** Rig (Stream Tools). **Tracking:** GitHub issues.

## Setup and run

Use [README.md](README.md) for purpose and context. On the stream gaming PC, run the right `.ahk` entry script with **AutoHotkey v1** and edit the matching `*-Config.ini` (GEO, NDG, NSRP, GTAV). Do not commit personal machine paths as defaults.

## Tests and checks

Every PR runs CI (`no-new-comments.yml`, `blast-radius.yml`). Before you ask for merge, run the commands in [AGENTS.md](AGENTS.md) under **Prove a change**, plus blast-radius on your PR body in `pr.md`. CI's `no-new-comments.yml` also runs `no_secrets.py` and `test_no_secrets.py`, which are not in that local list.

| Workflow | What it enforces |
|---|---|
| `no-new-comments.yml` | No secrets (`no_secrets.py`), no new code comments (`no_new_comments.py`), required [AGENTS.md](AGENTS.md) headings |
| `blast-radius.yml` | Filled-in `## Blast radius` on the PR body (`blast_radius_check.py`) |

Landmines and enforcers: [AGENTS.md](AGENTS.md) **Landmines** and **Pointers**.

## Branch and PR flow

1. Open a GitHub issue: problem, evidence, acceptance criteria.
2. Branch from `master`: `cursor/<issue#>-<slug>`. Never commit or push directly to `master`.
3. **One item per PR** — one issue, one scoped change.
4. PR body (see `.github/pull_request_template.md` and `tools/ci/blast_radius_fixtures/pass.md`):
   - `Closes #<issue>` (or equivalent link to the issue).
   - `## For Dread` with **Ask**, **What changes for you**, **Proof** (`https://` links to Actions runs or SHA-pinned blob URLs), **NOT done**.
   - **Owner seat:** Rig (name here if someone else will merge).
   - `## Blast radius` — concrete areas this diff can affect outside the changed files, or why nothing else depends on it, plus what you checked (not TBD).
   - Standalone `Level: 1` or `Level: 2` line when the change needs it (see pass fixture).
   - What changed, why, test plan and results, risk or rollback as needed.
5. CI green. Never skip hooks or checks; no force-push to shared branches.
6. **Grader** (not the author) reviews; default verdict **FAIL** until evidence supports **PASS**. Horde QA posts a PR comment like `**Horde QA independent grade: PASS|FAIL @ <sha7>**`.
7. **Merge:** on TEST repos, the **owner seat** merges only after **Horde QA PASS** (CI green + grader PASS) **and** your local proof from [AGENTS.md](AGENTS.md). Do not merge your own PR.
8. After merge: confirm the issue closed and post-merge CI passed; note the PR link on the issue.

Images committed to this repo must be inside a password-protected archive.

## Team rules

- **No secrets** in git — use env vars or a secret store ([AGENTS.md](AGENTS.md); `no_secrets.py`).
- **No code comments** on added lines — any author, any language ([AGENTS.md](AGENTS.md); `no_new_comments.py`).
- **Paths:** this repo has no `safe_fs` helper. Scripts should read and write only their own folder and the matching `*-Config.ini`; never commit personal machine paths as defaults ([AGENTS.md](AGENTS.md)).
- **Never bypass** checks, hooks, graders, or gates; if a check is wrong, escalate — do not route around it.
- **Never** push to `master`, force-push, or merge your own PR ([AGENTS.md](AGENTS.md) **What is NOT allowed**).
