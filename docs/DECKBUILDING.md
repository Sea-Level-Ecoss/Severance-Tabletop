# Deckbuilding Flow (Presence vs Absence)

## Shared Rules

- Both roles can access macrocosm and microcosm cards.
- The difference is the ordering of taxon steps.
- Draft draws exclude incomplete cards.
- Incomplete cards remain searchable and can be manually added.
- Provide four UI actions:
  - Build Presence Deck
  - Build Absence Deck
  - Import Decklist
  - Search Cards

### Incomplete Card Handling (Playtest)

- `completion_status` values outside draw-eligible statuses are treated as **incomplete/manual-only**.
- Incomplete cards do not appear in taxon draft option draws.
- Incomplete cards can still be spawned manually by card id.
- Hover/inspect data includes backend fields to support tuning against complete cards.

## Taxon Step Order (Draft)

Based on the SS GDD taxonomy list:

Macro -> Micro (Presence):
1) Bin
2) Basin
3) Eco
4) Kingdom
5) Phylum
6) Class
7) Order
8) Family
9) Essa

Micro -> Macro (Absence):
1) Essa
2) Family
3) Order
4) Class
5) Phylum
6) Kingdom
7) Eco
8) Basin
9) Bin

## Build Presence Deck

- Start at the highest rank.
- Offer a choice pool at each step.
- The first choices define the early identity of the deck.

## Build Absence Deck

- Start at the lowest rank.
- Offer a choice pool at each step.
- Later choices layer macro-level shaping on top.

## Import Decklist

- Accept a list of card ids (one per line).
- Resolve via /api/cards/{id} and build a deck.

## Search Cards

- Query by name (client-side filter) and add to deck.
- Later: add API query for taxonomy or status.
- Search output is separated into:
  - draw-eligible
  - incomplete/manual-only

## Taxon Calculator (Presence / Absence)

- Two calculator objects are used, one per role.
- Current implementation reads taxons from cards in role play zones and resolves one displayed value per rank.
- `Essa` displays `1` when an object is present in the role's Essa zone object, otherwise `X`.
- Bin/Basin can be toggled on/off per role (visibility and backend participation).

### Combo Rules (Current)

- `3 in a row`: three connected adjacent taxon ranks share the same non-empty value.
- `two sets of two`: at least two adjacent pairs exist in the current rank chain.

### Combo Rules (Future)

- Add new combo detectors in the calculator combo evaluation layer without changing rank parsing.
- Keep combo output as a list so new combo types can be appended safely.

## Taxonomy Parity Fixtures (v1)

- Canonical fixture file: `docs/fixtures/taxonomy-parity-v1.json`
- Required parity vectors:
  - `presence_three_in_row`
  - `absence_two_sets_of_two`
  - `no_combo_baseline`

Expected process:
1. Load fixture vector by `id`.
2. Resolve displayed taxon chain for the mode (`presence` or `absence`).
3. Evaluate combo detectors.
4. Assert output matches `expected.three_in_a_row` and `expected.two_sets_of_two`.

Runnable check:
- `node tools/taxonomy-parity-check.js`

Contract rule:
- Any change to taxonomy rank ordering or combo semantics must update this fixture file first, then update the TTS implementation.
