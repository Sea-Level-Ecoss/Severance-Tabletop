# Severance-Tabletop

Tabletop Simulator workshop mod + card import pipeline for Severance.

## Goals (Milestone 1)

- Unlisted Steam Workshop item for playtests.
- TTS table with zones, tokens, and scripted deckbuilding.
- Live card import from GrilwurtBot API.

## Repo Structure

- docs/               Design, workflow, and workshop notes
- tts/                TTS save files, scripts, and UI
- tts/scripts/        Lua scripts for Global, objects, and UI
- tts/objects/        JSON object templates (if used)
- assets/             Images, board art, and tokens
- data/               Local cache for card data (ignored)
- tools/              Helper scripts (export, validation, etc.)

## Next Steps

- Define the TTS table layout and zones.
- Implement a minimal Global.lua with buttons:
  - Build Presence Deck
  - Build Absence Deck
  - Import Decklist
  - Search Cards
- Wire GrilwurtBot API calls and caching.

## Implementation Readiness Docs

- `docs/TTS_IMPLEMENTATION_READINESS.md` - milestone plan and acceptance criteria.
- `docs/TTS_OPEN_QUESTIONS.md` - blockers and decisions required before/through implementation.
- `docs/NAMING_BOUNDARY.md` - canonical terminology boundary for TTS vs Unity contexts.
