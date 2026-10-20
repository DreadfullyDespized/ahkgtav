# AutoHotkey Grand Theft Auto V

**Repo label: TEST** — see [CONTRIBUTING.md](CONTRIBUTING.md). Verified work merges to master, and Dread tests master.

AutoHotkey v1 scripts that automate repetitive chat commands and hotkey tasks in GTA V roleplay (FiveM), used on the gaming PC while streaming.

## Run this one: AHKGEO.ahk

`AHKGEO.ahk` is the live script. The others are legacy (see below).

- Requires **AutoHotkey v1.1 or newer** (the script checks and exits on anything older). There is no v2 version.
- Run `AHKGEO.ahk`; it relaunches itself as administrator, so expect a UAC prompt.
- Settings live in `GEO-Config.ini` beside the script (an example with placeholder values only is in `GEO-Config.example.ini`). Press **Ctrl+1** in game to edit them in the config window — role, callsign, name, department, phone, macro delay, report templates, and the three rebindable hotkeys.
- While it runs: NumLock is forced on, ScrollLock is forced off, and the script registers the global Windows-key hotkeys listed below.
- Updates: **Ctrl+4** (or tray → Update Checker) checks for a newer version.

## Hotkeys

| Keys | Action |
|---|---|
| Ctrl+1 | Configuration / help window |
| Ctrl+3 | Reload script |
| Ctrl+4 | Update Checker |
| Ctrl+5 | Police overlay |
| Ctrl+6 | Close police overlay |
| Ctrl+. | Spike strip toggle (rebindable in config) |
| Ctrl+/ | Vehicle image search (rebindable in config) |
| Ctrl+- | Run-plate prep (rebindable in config) |
| Win+Z | Show tray menu |
| Win+Del | Empty the recycle bin |
| Win+ScrollLock | Suspend / resume hotkeys |
| Win+Insert | Reload script |

## Typed commands

Type these in the FiveM chat. Which set is active depends on the role chosen in the config (LEO or TOW).

LEO: `tdutystart` (go on duty), `arrestreport`, `citationreport`, `searchreport`, `warrantreport`, `tmedical`, `ttrunk` (medbag, lockpick, cones, gsr, breathalizer, bodybag, spikes)

TOW: `tstart` (start tow shift), `ttow`, `tsecure`, `trelease`, `tkitty`

Any role: `tmic` (microphone fix help text), `tgeohelp` (server help text)

## The other scripts are legacy

| File | What it is |
|---|---|
| `AHKGTAV.ahk` | Older standalone variant (its own header identifies it as the NDG script, v5). Last changed 2019. |
| `AHKNDG.ahk` | New Dawn Gaming version. Last changed 2020. |
| `AHKNSRP.ahk` | NSRP version. Last changed 2021. |
| `loop-button-parse.ahk` | Small one-off GUI experiment. |

They are kept for reference. Fixes and features go into `AHKGEO.ahk` only.

## Working on this repo

Process, checks, and merge rules: [CONTRIBUTING.md](CONTRIBUTING.md). Agent outline and landmines: [AGENTS.md](AGENTS.md).
