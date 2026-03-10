# TTS Milestone A Acceptance Tests

Run these tests in TTS against the development save.

## Test 1: Role Select and Mode Entry

1. Load save.
2. Assign one player to Presence and one to Absence.
3. Click `Start Deckbuild Mode`.
4. Verify setup state updates and both roles are active.

Pass if:
- state changes to deckbuild mode
- no script errors

## Test 2: Guided Draft Core Flow

1. Run guided draft for both players.
2. Confirm each decision shows exactly 3 options.
3. Confirm picks increment decision progress.
4. Confirm duplicate card ids cannot be selected twice.

Pass if:
- progress is tracked correctly
- no invalid pool entries appear

## Test 3: Skip Budget Behavior

1. Use 1 skip and verify budget +1 (up to cap).
2. Use skips until max reached.
3. Attempt extra skip beyond max.

Pass if:
- skip behavior matches configured rules
- extra skip is rejected with clear message

## Test 4: Essa Gate

1. Attempt finalize without selecting Essa.
2. Select Essa for each player.
3. Retry finalize.

Pass if:
- finalize is blocked before Essa
- finalize allowed after Essa

## Test 5: Start Resolver

1. Draw 7 for both players.
2. Resolve first player by mana sum.
3. Validate tie-break path by forcing equal sums.

Pass if:
- first player always resolves
- tie-break output is deterministic

## Test 6: Save/Load Continuity

1. Stop mid-setup and save game.
2. Reload save.
3. Continue setup to completion.

Pass if:
- setup state is restored accurately

## Test 7: Stability Run

1. Complete full setup flow three times in a row.
2. Watch for script errors or stuck states.

Pass if:
- all three runs complete without reset
