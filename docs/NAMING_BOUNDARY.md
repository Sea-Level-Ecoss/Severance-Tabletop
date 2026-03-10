# Naming Boundary: Severance (TTS) vs Seventh Severance

This project requires strict naming boundaries for implementation clarity.

## Canonical Terms

1. `Severance (TTS)`
- Means the Tabletop Simulator implementation, PvP rules, save, scripts, and host flow.

2. `Seventh Severance`
- Means the Unity game title and Unity-runtime implementation context.

3. `Shared Card Schema`
- Means the card data model sourced from Grilwurt DB and consumed by multiple surfaces.

## Rules for Docs and Agent Output

1. Every feature ticket/spec must be tagged as one of:
- `TTS`
- `Unity`
- `Shared Card Schema`

2. Do not use `Seventh Severance` as a synonym for TTS runtime behavior.

3. If a behavior differs between surfaces, document it explicitly under separate headings.

4. If a behavior is shared, mark it as `Shared Card Schema` and avoid surface-specific assumptions.
