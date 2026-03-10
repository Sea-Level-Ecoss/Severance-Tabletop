# TTS Open Questions and Decision Log

Use this file to close blockers before implementation.

## Must Decide Before Milestone A Completion

1. First-player tie-break rule when opening hand mana sums are equal.
2. Exact taxon weighting progression curve across draft picks.
3. Minimum Essa schema required to start gameplay.
4. Draft pool composition guarantees (duplicates, rarity, card-type guards).

## Must Decide Before Milestone B Completion

1. Exact combat trigger payload fields from table state.
2. Which placed card effects persist into combat vs resolve before combat.
3. Round reset semantics after combat instance.
4. Match end and round win condition specifics for best-of series.

## Must Decide Before Milestone C Completion

1. Host permission model (role checks and fallback behavior).
2. Required hidden-information protections (hand/private zones/peek permissions).
3. Checkpoint storage format and retention policy.
4. Script integrity verification mechanism and display location.

## Working Assumptions (Current)

1. Two-player only (`Absence`, `Presence`) in this phase.
2. Card definitions come from Grilwurt DB payloads.
3. Players can either import a deck or use guided deckbuilding.
4. Setup completion is the first milestone target; deep zone automation follows.

## Decision Log

Append finalized decisions here using this template:

```
YYYY-MM-DD - <Decision Name>
- Decision:
- Reason:
- Impacted files/systems:
```
