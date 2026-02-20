# TTS Table Layout (Milestone 1)

## Overview

- 1v1 only. Two fixed seats: Absence (Player) and Presence (Boss).
- Central board for shared zone, with left/right sideboards.
- Top-down view should frame the board and both player zones.

## Table Orientation

- North = Presence side
- South = Absence side

## Zones (Draft)

### Shared

- Board Core (center): shared battlefield grid placeholder.
- Round Tracker strip (east side): tokens for rounds 1-9.
- Discard Pile (west side): shared discard for test mode.

### Presence (North)

- Deck zone (north-west)
- Hand zone (north-center)
- Play zone (north-center, front of hand)
- Banish/Exile zone (north-east)
- Role token (north-center): Presence marker
- Spawn coordinates (milestone script):
	- Deck: `(-22, 1.2, -18)`
	- Discard: `(-16, 1.2, -18)`

### Absence (South)

- Deck zone (south-west)
- Hand zone (south-center)
- Play zone (south-center, front of hand)
- Banish/Exile zone (south-east)
- Role token (south-center): Absence marker
- Spawn coordinates (milestone script):
	- Deck: `(22, 1.2, 18)`
	- Discard: `(16, 1.2, 18)`

## Tokens / Objects

- Round tokens: 1-9 (for the 3-round cadence).
- Role tokens: Presence, Absence.
- Taxon step marker: indicates current deckbuilding step.
- Draft pool markers: for Presence vs Absence draft piles.

## UI Entry Points

- Build Presence Deck
- Build Absence Deck
- Import Decklist
- Search Cards
- Pick Search ID
- Add Search ID Manually
- Skip Step
- Reroll Step
- Finalize Deck (Spawn)
- Refresh Card Cache

## Compact Round Tracker

- On-table compact tracker uses three buttons:
	- `R-` decrement round
	- `R:<n>` current round display (click to reset to 1)
	- `R+` increment round
- Intended for quick playtest cadence tracking without opening extra UI.

## Notes

- Keep layout minimal for now, then expand into art pass.
- Use a single board plane until we have final board geometry.
- Milestone script spawns locked zone markers for Presence/Absence deck + discard positions.
