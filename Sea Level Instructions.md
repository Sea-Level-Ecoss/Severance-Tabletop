# Sea Level Instructions

Read this file at the start of every Copilot chat before implementation work.

Required prompt convention:
- Start with: `read Sea Level Instructions`
- State machine context: `Laptop` or `Server Computer`

## Machine Roles

### Laptop (preferred)
- Primary for content/worldbuilding/web docs and Unity-side authoring.

### Server Computer (preferred)
- Primary for runtime-integrated development, bot features, and TTS+bot workflows.

## Source of Truth + Git Flow

- Use feature branches and Pull Requests to `main`.
- Server machine should usually pull `main` and run workloads, not host long-lived feature branches.
- Emergency server fixes still go through `hotfix/*` branch + PR.

## Agent Behavior Requirements

- Confirm machine context before workflow/tooling choices.
- Read `.github/copilot-instructions.md` and `SERVER_LAPTOP_PR_WORKFLOW.md` for repo-specific constraints.
- If instructions conflict, apply:
  1) User request
  2) Repo copilot instructions
  3) Sea Level Instructions
