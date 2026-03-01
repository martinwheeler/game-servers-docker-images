# Purpose

This repository builds and publishes a Docker image for a **Terraria** dedicated server. The guidance below captures the minimal, project-specific knowledge an AI coding agent needs to be productive: architecture, build/publish flows, runtime configuration, and notable file locations.

## Big picture

- This repo produces a Docker image based on `cm2network/steamcmd:root` (for compatibility with the steam user and base tooling) but the server files are downloaded from the official Terraria website rather than SteamCMD.
- Entrypoint behavior is implemented in `etc/entry.sh` and `etc/tinientry.sh` (the container runs `tini` and then `tinientry.sh`, which invokes `entry.sh`).
- The `Dockerfile` no longer has multiple build targets; it simply installs required utilities, copies the entry scripts, and exposes port 7777.

## Key files

- `Dockerfile` — primary build logic. Copies `etc/entry.sh` and `etc/tinientry.sh`, defines Terraria-related ENV defaults and `ENTRYPOINT`.
- `etc/entry.sh` — downloads the Terraria server zip, extracts the Linux binaries, optionally creates `serverconfig.txt` from environment variables, and launches the server.
- `etc/tinientry.sh` — simple wrapper that runs `entry.sh` under `tini`.
- `build` — convenience script: builds the Terraria image with `--no-cache`.
- `README.md` — contains user-facing runtime examples and notes (mounts, env vars, config file, persistency).

## Build / publish flows (concrete)

- Build locally (examples in `build`):
  - `./build` (runs a single `docker build --no-cache` command) to create `martingwheeler/terraria:latest`.
- Push: use your preferred `docker push` command; a simple `docker push martingwheeler/terraria:latest` suffices.
  (there is no `push` script any longer).

## Runtime configuration (essential details)

- Configured via environment variables in the `Dockerfile` and documented in `README.md` (see `TERRARIA_*` variables and `ADDITIONAL_ARGS`).
- The entry script generates a `serverconfig.txt` from environment variables and passes `-config` to the server binary.
- Persist world files using a host bind or properly owned Docker volume mounted at `/home/steam/.local/share/Terraria`.
- The container downloads/updates the Terraria server zip on each start; restarting pulls any new release.

## Patterns & conventions for agents

- Prefer editing `etc/entry.sh` or `etc/tinientry.sh` for runtime behavior changes rather than embedding logic in `Dockerfile`.
- When adding features that touch runtime flags, update the `ADDITIONAL_ARGS` placeholder handling in `tinientry.sh`.
- Preserve existing environment-variable defaults in `Dockerfile` when adding new vars; document them in `README.md`.
- Use `build` and `push` scripts for CI automation to keep command lines simple.

## Debugging and logs

- Server log path default: `logs_output/outputlog_server.txt` (controlled by `SERVER_LOG_PATH`).
- Use host mounts for logs and save dirs when reproducing issues locally.

## Integration points / external dependencies

- Terraria server binaries are fetched directly from `https://terraria.org/api/download/pc-dedicated-server/terraria-server-${TERRARIA_VERSION}.zip` (version controlled via `TERRARIA_VERSION`).

## Windows / Git-Bash considerations

When running any Docker commands on Windows using Git-Bash or MSYS, **always prefix with `MSYS_NO_PATHCONV=1`** to prevent path mangling. Git-Bash incorrectly translates forward slashes and colons (e.g., volume mount separators) to Windows paths, resulting in malformed mount points.

Example:

```bash
# Correct on Windows with Git-Bash:
MSYS_NO_PATHCONV=1 docker run -v ~/terraria-worlds:/home/steam/terraria …

# Also correct: use absolute Windows paths (no translation needed)
docker run -v C:/Users/marti/terraria-worlds:/home/steam/terraria …
```

Without this prefix you'll see odd folder names like `terraria-worlds;C` or errors about paths not existing.

## What I preserved from the repository

- The README's concrete Docker usage examples and mount paths are the canonical source of runtime behavior — keep them authoritative.
- Record any new deployment patterns or CLI conventions here so future work stays consistent.

## If anything is missing or unclear

- Tell me which areas you'd like expanded (CI, tagging conventions, multi-arch builds, or runtime tests) and I'll iterate.

---

If you want, I can also add short CI snippets (GitHub Actions) that run the `build` and `push` scripts and validate the image tags.
