# Tools

Helper scripts for export, validation, and save injection.

## TTS Save Injection

- Auto-target latest Severance Playtest save (from TTS metadata):
	- `node ./tools/inject-tts-save.js`
- Inject into a fixed manual save slot (recommended for stable iteration):
	- `./tools/inject-tts-save-manual.ps1`
	- Defaults to slot `20` (`TS_Save_20.json`)
	- Defaults save display name to `[DEV] Severance Playtest`

### Manual Slot Options

- Choose slot and display name:
	- `./tools/inject-tts-save-manual.ps1 -SaveSlot 20 -SaveName "Severance Playtest"`

If the target manual slot JSON does not exist, the script initializes it from `TS_AutoSave.json` first, then injects `tts/scripts/Global.lua` and `tts/scripts/ui.xml`.

## Recommended Save Convention

- `TS_Save_20.json` → primary development save (always load this one)
- Display name in TTS list: `[DEV] Severance Playtest`
- `TS_AutoSave.json` → safety net only (do not use as primary target)

## Development Rhythm (Reliable)

1. Make script/UI edits in VS Code.
2. Run `./tools/inject-tts-save-manual.ps1`.
3. Open TTS and load slot 20 (`[DEV] Severance Playtest`).
4. Place/move objects manually in TTS.
5. Save in TTS, then return to step 1 for next script pass.

This keeps scene building and Lua/script iteration predictable and avoids autosave targeting confusion.

## Server Repo Sync (All Projects)

From a machine that hosts your bot/runtime services, you can clone-or-pull all Sea Level repos in one pass:

- `./tools/sync-all-sea-level-repos.ps1`
- Optional root override:
	- `./tools/sync-all-sea-level-repos.ps1 -RootDir "D:/Sea Level"`

The script covers:

- AntiPwr.github.io
- Seventh-Severance-Unity
- Sea-Level-Launcher
- Severance-Tabletop
- VivBot
- GrilwurtBot
