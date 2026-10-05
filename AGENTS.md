# AGENTS.md

Short outline for agents. Process detail lives in CONTRIBUTING.md.

## What this repo is for

AutoHotkey v1 scripts that automate repetitive chat and hotkey tasks in GTA V roleplay (GEO, NDG, NSRP), used on stream from the gaming PC. This is a TEST repo.

## What is allowed in this repo

- AutoHotkey v1 scripts, their `.ini` configs and changelogs.
- Checks under `tools/` and the workflows that run them.
- Docs: `README.md`, `CONTRIBUTING.md`, `AGENTS.md`.

## What is NOT allowed

- Secrets, tokens, or personal machine paths added as defaults.
- Code comments in added lines.
- Images outside a password-protected archive.
- Pushing to `master`, force-pushing, or merging your own PR.

## Prove a change

Run these exact commands from the repo root (Linux box):

```bash
python3 tools/checks/no_new_comments.py --base origin/master --head HEAD
python3 tools/checks/agents_md_headings.py
python3 -m unittest discover -s tools/checks/tests -p "test_no_new_comments.py" -v
python3 -m unittest discover -s tools/checks/tests -p "test_agents_md_headings.py" -v
python tools/ci/blast_radius_check.py --body-file pr.md
```

Put the PR body in `pr.md` for the blast-radius check. Docs-only wording changes: the commands above are enough.

## Grader and merge

Grader starts at FAIL. The person who wrote the change does not grade it. TEST = owner merges after PASS + local proof. PROD = Dread merges only. ASK (ahkglrp) = Dread sets tier.

## Correction loop

No correction-loop doc yet — follow CONTRIBUTING if present.

## Landmines

- Never add code comments → `tools/checks/no_new_comments.py` / `no-new-comments.yml`
- Never omit ## Blast radius (or leave it empty) → `tools/ci/blast_radius_check.py` / `blast-radius.yml`
- Never delete Required AGENTS.md headings → `tools/checks/agents_md_headings.py`
- Never add personal machine paths as defaults → reviewers + CONTRIBUTING

## Pointers

- Process and rule table: [CONTRIBUTING.md](CONTRIBUTING.md)
- Environment and usage: [README.md](README.md)
- CI checks in `.github/workflows/`: `no-new-comments.yml` (`tools/checks/no_new_comments.py`, `tools/checks/agents_md_headings.py`), `blast-radius.yml` (`tools/ci/blast_radius_check.py`)
