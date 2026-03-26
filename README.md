# Game Server Branch Automation

The `main` branch no longer builds a Docker image. Image definitions now live in the
`game/*` branches, and `main` only keeps the workflow that monitors Terraria server
releases.

## What lives here

- `.github/workflows/update-terraria-version.yml` runs on a schedule and checks out
  `game/terraria` before making any changes.
- High-level documentation about how `main` coordinates automation across the game branches.

## How the scheduled updater works

The workflow runs hourly and manually via `workflow_dispatch`. It checks out the
`game/terraria` branch, runs the updater scripts from that branch, commits any version bump there,
and pushes the change back to `origin/game/terraria`.

All Terraria-specific files such as `.terraria.env`, the updater scripts, and the Docker build
definition now live only in `game/terraria`.
