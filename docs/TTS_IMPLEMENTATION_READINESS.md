# Severance (TTS) Implementation Readiness

This document converts current product direction into executable milestones for the private dev alpha save.

## Scope Lock

- Surface: `Severance (TTS)` only.
- Goal: private playable alpha save usable via Steam invites.
- Card source of truth: Grilwurt card database.
- Shared card identity is accepted; no Unity/TTS card divergence tracking in this phase.
- Automation target: high automation.

## Milestone A: Setup Alpha (Implement First)

### Objective

Enable two players to complete setup and enter gameplay with no manual object editing.

### Required Features

1. Role assignment: `Absence` and `Presence`.
2. Mode switch buttons:
   - `Start Deckbuild Mode`
   - `Return to Base Mode`
3. Draft engine:
   - 40 pick decisions per player
   - 3 card choices per decision
   - 7 skips per player
   - skip adds +1 future choice set (max 47 shown)
4. Taxon weighting:
   - Presence starts high-taxons
   - Absence starts low-taxons
   - progression convergence over time
5. Essa selection before first draw.
6. Start-of-game resolver:
   - draw 7 cards each
   - determine first player by summed mana costs
   - deterministic tie-break rule

### Acceptance Criteria

1. Setup flow completes in one continuous scripted path.
2. Illegal transitions are blocked (cannot start rounds before decks + Essa lock).
3. State survives save/load within the same match.

## Milestone B: Round Cycle + Combat Trigger

### Objective

Run stable table rounds and trigger combat instance every third round block.

### Required Features

1. Turn manager (2 players alternating).
2. Round manager (3 rounds card phase).
3. Combat trigger on 7th phase instance.
4. Combat payload builder from placed cards/zones/tokens.
5. Match format controller (best-of-3 baseline, configurable to 5/7).

### Acceptance Criteria

1. Cycle is repeatable for 10+ loops without script desync.
2. Trigger payload contains all required card/effect state.
3. Post-combat return to next cycle works automatically.

## Milestone C: Shareable Save Hardening

### Objective

Secure and recoverable save suitable for private distribution and later Workshop handoff.

### Required Features

1. Host-authoritative controls for critical state transitions.
2. Hidden-info and zone lock enforcement.
3. Checkpoints:
   - pre-draft
   - post-draft
   - pre-combat trigger
4. Script fingerprint/version display.
5. Recovery actions:
   - phase reset
   - checkpoint restore
   - deterministic RNG reseed

### Acceptance Criteria

1. Non-host users cannot invoke restricted state transitions.
2. Corrupt state recovery takes under 60 seconds.
3. Save behavior is reproducible across host machines.

## Repo Responsibilities

### Severance-Tabletop

- TTS save structure, Lua scripts, zones, state machine, host controls.
- Player-facing and host-facing docs.
- Build/injection tooling for save packaging.

### Grilwurt-Bot

- Card DB authority.
- TTS export payload generation.
- Data contract validation for TTS required fields.

## Definition of Ready (Implementation Start)

Implementation should start when:

1. Tie-break rule for first player is finalized.
2. Draft weighting schedule is finalized.
3. Essa minimum data schema is finalized.
4. Combat trigger payload schema is finalized.

Track remaining items in `docs/TTS_OPEN_QUESTIONS.md`.

## Execution Docs

- `docs/TTS_MILESTONE_A_SPEC.md`
- `docs/TTS_IMPLEMENTATION_TASKS.md`
- `docs/TTS_MILESTONE_A_TESTS.md`
