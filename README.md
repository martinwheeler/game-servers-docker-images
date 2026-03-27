# Game Server Branch Automation

The `main` branch does not contain the Docker image definitions themselves. Those still live in
the `game/*` branches. `main` now keeps the shared GitHub Actions entry points for manual image
builds, plus the scheduled version updater workflows.

## What lives here

- `.github/workflows/build-*.yml` provides manual `workflow_dispatch` entry points from the
  default branch UI and checks out the corresponding `game/*` branch before building.
- `.github/workflows/update-minecraft-version.yml` runs on a schedule or manually and checks out
  `game/minecraft` before making any changes.
- `.github/workflows/update-terraria-version.yml` runs on a schedule or manually and checks out
  `game/terraria` before making any changes.
- High-level documentation about how `main` coordinates automation across the game branches.

## How the workflows work

The manual build workflows run from the default branch so GitHub shows the `Run workflow` form and
its input fields. Each build workflow checks out the relevant `game/*` branch, uses its scripts and
env files, and publishes the resulting Docker image.

The updater workflows run hourly and manually via `workflow_dispatch`. They check out the matching
game branch, run the updater scripts from that branch, commit any version bump there, and push the
change back to the same remote game branch.

All game-specific files such as the env files, updater scripts, and Docker build definitions still
live only in their respective `game/*` branches.
