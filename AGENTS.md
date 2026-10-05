# AGENTS.md

Short outline for agents. Process detail lives in CONTRIBUTING.md; this file does not repeat it.

## What this repo is for

AutoHotkey v1 scripts that automate repetitive chat and hotkey tasks in GTA V roleplay (GEO, NDG, NSRP), used on stream from the gaming PC. TEST repo: Rig merges after a separate grader PASS.

## What is allowed in this repo

- AutoHotkey v1 scripts, their `.ini` configs and changelogs.
- Checks under `tools/` and the workflows that run them.
- Docs: `README.md`, `CONTRIBUTING.md`, `AGENTS.md`.

## What is NOT allowed

- Secrets, tokens, or personal machine paths added as defaults.
- Code comments in added lines.
- Images outside a password-protected archive.
- Pushing to `master`, force-pushing, or merging your own PR.

## Pointers

- Process and rule table: [CONTRIBUTING.md](CONTRIBUTING.md)
- Environment and usage: [README.md](README.md)
- CI checks in `.github/workflows/`: `no-new-comments.yml` (`tools/checks/no_new_comments.py`), `blast-radius.yml` (`tools/ci/blast_radius_check.py`)
