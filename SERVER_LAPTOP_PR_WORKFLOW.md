# Server/Laptop PR Workflow

Use this process when developing on laptop and deploying/running on the server machine.

## Branch + PR rule

1. Create a feature branch on laptop from `main`.
2. Commit focused changes.
3. Push branch to origin.
4. Open a Pull Request into `main`.
5. Merge PR after checks/review.
6. On server machine, pull `main` only.

## Server machine rule

- Server is runtime/stability-first.
- Do not do long-lived feature development directly on server `main`.
- Use server for validation and operational checks.

## Pull commands on server

```powershell
git checkout main
git pull --rebase origin main
```

## Emergency hotfix

If a production hotfix is required from server:

1. Create `hotfix/<short-name>` branch.
2. Commit + push.
3. Open PR to `main`.
4. Merge PR.
5. Pull `main` again on server.

## Server switch startup (agent)

When moving to server and starting a fresh Copilot chat:

1. Pull latest `main` first:

```powershell
git checkout main
git pull --ff-only origin main
```

2. Start chat with:
	- `read Sea Level Instructions`
	- `Machine: Server Computer`
	- `Read .github/copilot-instructions.md and SERVER_LAPTOP_PR_WORKFLOW.md, then confirm constraints before implementation.`
