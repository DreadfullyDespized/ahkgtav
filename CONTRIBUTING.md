# Contributing to ahkgtav

**Repo label: TEST** — All branches = TEST; the owner seat merges when the process below is complete.
**Owner seat:** Rig (Stream Tools).
**Tracking:** GitHub issues.

## Process (required for every change, no exceptions)
1. Open a GitHub issue first: problem, evidence, acceptance criteria.
2. Branch `cursor/<issue#>-<slug>`. Never commit directly to `main`.
3. One scoped PR per issue. Body: `Closes #<issue>`, what, why, evidence (run links/logs/file:line), test plan + results, risk/rollback.
4. CI green. Never skip hooks or checks; no force-push to shared branches.
5. Review by someone other than the author (grader ≠ doer); resolve all threads.
6. Merge: TEST → the owner merges when steps 1–5 are done. PROD → human merge only.
7. After merge: confirm the issue closed and post-merge CI/deploy passed; update the tracking card with PR link + evidence.

Images committed to this repo must be inside a password-protected archive.
