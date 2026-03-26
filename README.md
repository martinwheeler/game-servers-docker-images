# Game Server Branch Automation

The `main` branch no longer builds a Docker image. Image definitions now live in the
`game/*` branches, and `main` only keeps the shared automation needed to monitor Terraria
server releases.

## What lives here

- `.github/workflows/update-terraria-version.yml` runs on a schedule and checks out `game/terraria`
  before making any changes.
- `.terraria.env` stores the pinned Terraria server version.
- `scripts/get-terraria-version.sh` reads the currently pinned version.
- `scripts/update-terraria-version.sh` checks Terraria's API and updates `.terraria.env` when a
  newer dedicated server build is available.

## How the scheduled updater works

The workflow runs hourly and manually via `workflow_dispatch`. It checks out the
`game/terraria` branch, updates `.terraria.env` when needed, commits the version bump, and pushes
the change back to `origin/game/terraria`.

## Local usage

Read the pinned version:

```sh
./scripts/get-terraria-version.sh
```

Check for a newer Terraria server version and update `.terraria.env` locally:

```sh
./scripts/update-terraria-version.sh
```

If the script reports no changes, the pinned version is already current.
