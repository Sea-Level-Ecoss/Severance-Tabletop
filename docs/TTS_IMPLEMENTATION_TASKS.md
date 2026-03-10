# TTS Implementation Task Matrix

This is the coding execution order for Milestone A.

## Progress Snapshot

- PR-1 complete on branch `feature/tts-implementation-readiness` at commit `2ab8897`.
- PR-2 started at commit `29d9379` with a decision-budget draft loop (`decision x / budget`) replacing strict step progression.
- Remaining work is focused on weighted pool selection + legality hardening for the full 40/47 guided draft target.

## Task Group 1: Setup State Machine

File: `tts/scripts/Global.lua`

1. [x] Add setup phase enum:
- `base`
- `role_select`
- `deckbuild`
- `essa_select`
- `start_resolve`

2. [x] Add host-gated transition functions.

3. [x] Persist setup state via `onSave`/`onLoad`.

## Task Group 2: Guided Draft Engine (40 + skips)

File: `tts/scripts/Global.lua`

1. Replace step-based progression with decision-based progression.
2. Add skip behavior:
- increment `skipsUsed`
- increment decision budget if `< maxDecisionBudget`
3. Add weighted pool selector by role + decision index.
4. Ensure no duplicate card ids in player picks.

## Task Group 3: Essa Selection Gate

Files:
- `tts/scripts/Global.lua`
- `tts/scripts/ui.xml`

1. [x] Add Essa selection input/action.
2. [x] Validate Essa exists in cached card pool.
3. [x] Block finalize/start until Essa locked.

## Task Group 4: Start Resolver

File: `tts/scripts/Global.lua`

1. [x] Draw 7 per player from resolved deck object.
2. [x] Parse mana value from drawn cards.
3. [x] Resolve first player:
- compare sums
- apply tie-break.
4. [x] Broadcast decision and write to setup status state.

## Task Group 5: UI and UX Completion

Files:
- `tts/scripts/ui.xml`
- `tts/scripts/Global.lua`

1. [x] Add `Start Deckbuild Mode` and `Return to Base Mode` actions.
2. [x] Add setup progress line (`decision`, `skips`, `essa`, `first player`).
3. [x] Add failure messages for invalid transitions.

## Task Group 6: Acceptance Test Script

Files:
- `docs/TTS_MILESTONE_A_TESTS.md` (new)
- optional helper in `tools/`

1. Create manual test checklist for all setup paths.
2. Add repeatability test (3 sequential setup runs).
3. Add save/load continuity test.

## Suggested PR Slices

1. PR-1: setup state + UI mode controls.
2. PR-2: 40-decision draft + skip budget logic.
3. PR-3: Essa gate + start resolver + first-player decision.
4. PR-4: polish + acceptance checklist.
