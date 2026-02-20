# Architecture

## Core Components

- TTS Mod: Table, zones, tokens, and UI.
- Script Layer: Global.lua handles API calls and deckbuilding flows.
- Data Cache: Local cache of card data from GrilwurtBot API.

## API Source

- GrilwurtBot API (cards.db)
- Base endpoint (local, configurable)

## Deckbuilding Flow (Draft)

- Presence: start at macrocosm, step down taxons.
- Absence: start at microcosm, step up taxons.
- Both can access all taxons; the ordering shapes choices.

## UI Actions

- Build Presence Deck
- Build Absence Deck
- Import Decklist
- Search Cards
