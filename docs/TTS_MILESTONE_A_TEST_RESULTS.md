# TTS Milestone A Test Results

Date: 2026-03-10
Branch: `feature/tts-implementation-readiness`

## Scope

This record captures PR-4 acceptance-pass status for Milestone A.

## Verification Summary

1. Static/editor validation completed.
- `tts/scripts/Global.lua`: no diagnostics reported.
- `tts/scripts/ui.xml`: no diagnostics reported.

2. Behavior checks validated from code paths.
- Skip budget now rejects extra skips beyond cap with explicit message.
- Guided decision options now attempt top-up from fallback eligible pool to maintain 3-option decisions when possible.
- Setup/start resolver preconditions are enforced (dual-role claim, distinct colors, mode/Essa gating, hand-resolution gating).
- First-player resolver state is persisted (`firstPlayer`, mana sums, tie-break flag).

3. Runtime checks pending in Tabletop Simulator.
- Full in-engine execution of `docs/TTS_MILESTONE_A_TESTS.md` remains required.
- Tie-break scenario should be forced and observed in-game to confirm deterministic output text.
- Save/reload continuity should be verified by running mid-setup save + reload.

## Test Case Status

- Test 1: Role Select and Mode Entry: Pending in-engine run
- Test 2: Guided Draft Core Flow: Pending in-engine run
- Test 3: Skip Budget Behavior: Code-path validated, in-engine confirmation pending
- Test 4: Essa Gate: Code-path validated, in-engine confirmation pending
- Test 5: Start Resolver: Code-path validated, in-engine confirmation pending
- Test 6: Save/Load Continuity: Pending in-engine run
- Test 7: Stability Run: Pending in-engine run

## Exit Criteria For Milestone A

Milestone A is implementation-complete in code and ready for in-engine validation. Final acceptance requires executing all seven tests in `docs/TTS_MILESTONE_A_TESTS.md` inside Tabletop Simulator and recording pass/fail outcomes.
