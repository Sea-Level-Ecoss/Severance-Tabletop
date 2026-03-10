# TTS Object Registry

Canonical object and zone names for the current local development save (`TS_Save_20.json`).

## Objects

- `Absence Right Split Deck`
- `Absence Right Split`
- `Absence Essa Right Split`
- `Absence Deck`
- `Absence Center`
- `Absence Essa`
- `Absence Left Split Deck`
- `Absence Left Split`
- `Absence Essa Left Split`
- `Absence Deckbuilder`
- `Absence Taxon Calculator`
- `Absence Rulebook`
- `Presence Rulebook`
- `Presence Taxon Calculator`
- `Presence Deckbuilder`
- `Presence Left Split`
- `Presence Essa Left Split`
- `Presence Left Split Deck`
- `Presence Center`
- `Presence Essa`
- `Presence Deck`
- `Presence Right Split`
- `Presence Essa Right Split`
- `Presence Right Split Deck`

## Zones

- `Presence Field`
- `Mean Field`
- `Absence Field`
- `Presence Hand`
- `Absence Hand`

## Notes

- Script logic now supports these names as fallback discovery for:
  - deck lookup (`Presence Deck`, `Absence Deck`)
  - play-zone refresh triggers (`Presence Field`, `Absence Field`, `Mean Field`)
  - rulebook and taxon calculator object lookup
- Tags remain preferred where present; names are fallback compatibility.
- In-game validator is available via:
  - UI button: `Validate Scene Wiring`
  - Context menu: `Validate Scene Wiring`