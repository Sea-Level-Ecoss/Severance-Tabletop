# Copilot Instructions

## Cross-machine policy

- Follow `SERVER_LAPTOP_PR_WORKFLOW.md`.
- Preferred flow:
  - Laptop: feature branch -> commit -> push -> PR -> merge to `main`.
  - Server: pull `main` only.
- Avoid direct server commits to `main` except emergency hotfix branches.
