# TTS Milestone A Technical Spec

Milestone A goal: deliver a stable setup phase for private alpha (role select, deck path choice, guided draft, Essa selection, first draw/first player).

## Functional Target

1. Two players join and lock to `Absence` or `Presence`.
2. Host chooses setup path:
   - guided draft
   - deck import
3. Guided draft supports:
   - 40 pick decisions
   - each decision shows 3 cards
   - 7 skips (skip adds one additional decision opportunity)
   - hard cap of 47 decisions shown
4. Each player selects Essa before game start.
5. Start-of-game resolver:
   - draw 7 cards each
   - decide first player by opening-hand mana sum
   - apply deterministic tie-break.

## Proposed Defaults (Implementation Seed)

These defaults should be used unless replaced by a finalized decision.

1. First-player tie-break
- If mana sums tie, Presence wins tie-break in Milestone A.

2. Draft taxon weighting schedule
- Presence: weighted high-taxons early, linear taper to mixed pool by decision 30.
- Absence: weighted low-taxons early, linear taper to mixed pool by decision 30.
- Decisions 31-47: mixed pool with mild role bias (55/45).

3. Essa minimum schema (Milestone A)
- `id`
- `display_name`
- `starting_effects` (array)
- `starting_hand_additions` (array card ids)

4. Draft legality baseline
- no duplicate pick of same card id in one player deck.
- no incomplete cards in guided draft pool.
- incomplete cards allowed via manual add path only.

## Current Script Gap Mapping

Existing `tts/scripts/Global.lua` supports role draft flow but differs from target:

1. `config.picksPerStep` currently represents picks per taxon step, not 40 decision flow.
2. Draft currently iterates taxon steps; it does not yet track 40 decision windows.
3. Skip currently advances step; it does not add additional decision budget.
4. No explicit Essa lock gate before finalize/start.
5. No first-player resolver from opening-hand mana sum.

## Required Data Structures

Suggested additions to `state.deckbuild`:

```lua
{
  role = "presence" | "absence",
  mode = "guided" | "import",
  decisionIndex = 1,
  decisionBudget = 40,
  maxDecisionBudget = 47,
  skipsUsed = 0,
  maxSkips = 7,
  pickedIds = {},
  pickedCards = {},
  currentOptions = {},
  essaId = nil,
  setupLocked = false,
}
```

## UI Additions (Milestone A)

Add/repurpose buttons:

1. `Start Deckbuild Mode`
2. `Return to Base Mode`
3. `Select Essa`
4. `Resolve Starting Hands`
5. `Resolve First Player`

Status text should include:

- role
- decision progress (`x / budget`)
- skips used
- Essa selected (`yes/no`)

## Definition of Done (Milestone A)

1. Both players can complete setup without manual object/script edits.
2. Illegal sequence guards are enforced:
- cannot finalize without Essa selected
- cannot resolve first player before both hands drawn
3. Save/load keeps setup state accurately.
4. Three repeated setup runs produce deterministic first-player output given same opening hands.
