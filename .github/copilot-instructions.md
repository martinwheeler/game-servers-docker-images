# Purpose

This repository builds and publishes a Docker image for a Valheim dedicated server (two variants: `:latest` / `:base` and `:plus`). The guidance below captures the minimal, project-specific knowledge an AI coding agent needs to be productive: architecture, build/publish flows, runtime configuration, and notable file locations.

## Big picture

- This repo produces a Docker image based on `cm2network/steamcmd:root` that installs Valheim via SteamCMD and optionally deploys the ValheimPlus mod (bookworm-plus target).
- Entrypoint behavior is implemented in `etc/entry.sh` and `etc/tinientry.sh` (the container runs `tini` and then `tinientry.sh`, which invokes `entry.sh`).
- Two image targets in the `Dockerfile`: `bookworm-base` (default server) and `bookworm-plus` (includes V+ Reforged). Use build targets to produce the correct tag.

## Key files

- `Dockerfile` — primary build logic. Copies `etc/entry.sh` and `etc/tinientry.sh`, defines ENV defaults and `ENTRYPOINT`.
- `etc/entry.sh` — updates Valheim via SteamCMD and launches the server. Contains the runtime command templates for both base and plus variants.
- `etc/tinientry.sh` — injects `ADDITIONAL_ARGS` into `entry.sh` and calls it.
- `build` — convenience script: builds both `bookworm-base` and `bookworm-plus` targets.
- `push` — convenience script: pushes all tags using `${DOCKER_REPO}`.
- `README.md` — contains user-facing runtime examples and notes (mounts, port behavior, persistency).

## Build / publish flows (concrete)

- Build locally (examples in `build`):
  - `./build` (runs two `docker build` commands)
  - Equivalent manual commands:
    - `docker build --target=bookworm-base -t martingwheeler/valheim:latest -t martingwheeler/valheim:base --no-cache .`
    - `docker build --target=bookworm-plus -t martingwheeler/valheim:plus --no-cache .`
- Push:
  - `DOCKER_REPO=martingwheeler/valheim ./push` or run `./push` after exporting `DOCKER_REPO`.

## Runtime configuration (essential details)

- Configured via environment variables in the `Dockerfile` and documented in `README.md` (e.g. `SERVER_PORT`, `SERVER_NAME`, `SERVER_PW`, `SERVER_WORLD_NAME`).
- Important port behavior: Steam query port = `SERVER_PORT + 1`. When running multiple instances, increment `SERVER_PORT` by two to avoid conflicts.
- Persist world files using host bind or Docker volumes. Note: `:plus` saves worlds in a different path — see `README.md` for exact locations.
- Container updates the game on startup (SteamCMD); restarting the container pulls updates.

## Patterns & conventions for agents

- Prefer editing `etc/entry.sh` or `etc/tinientry.sh` for runtime behavior changes rather than embedding logic in `Dockerfile`.
- When adding features that touch runtime flags, update the `ADDITIONAL_ARGS` placeholder handling in `tinientry.sh`.
- Preserve existing environment-variable defaults in `Dockerfile` when adding new vars; document them in `README.md`.
- Use `build` and `push` scripts for CI automation to keep command lines simple.

## Debugging and logs

- Server log path default: `logs_output/outputlog_server.txt` (controlled by `SERVER_LOG_PATH`).
- Use host mounts for logs and save dirs when reproducing issues locally.

## Integration points / external dependencies

- SteamCMD (via `cm2network/steamcmd:root`). The repo relies on online Steam updates and the V+ Reforged release tarballs when `VALHEIM_PLUS_VERSION` is set.
- ValheimPlus releases are downloaded directly in `etc/entry.sh` when `VALHEIM_PLUS_VERSION` is present.

## What I preserved from the repository

- The README's concrete Docker usage examples and the precise save-directory differences between `:latest` and `:plus` images are the canonical source of runtime behavior — keep them authoritative.

## If anything is missing or unclear

- Tell me which areas you'd like expanded (CI, tagging conventions, multi-arch builds, or runtime tests) and I'll iterate.

---

If you want, I can also add short CI snippets (GitHub Actions) that run the `build` and `push` scripts and validate the image tags.
