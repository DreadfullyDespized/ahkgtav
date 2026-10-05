## For Dread
**Ask:** Nothing
**What changes for you:** A small tweak.
**Proof:** https://github.com/DreadfullyDespized
**NOT done:** Nothing

## Blast radius
- The nightly sync job imports `load_points()`, so a change to its return shape breaks the sync.
- Nothing else calls it: `rg load_points` finds only this file and the job.

Level: 2
