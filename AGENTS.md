# AGENTS.md — game-servers-docker-images (Valheim)

Context for AI agents working on this repository. Read this before changing build,
CI, or version-pinning logic.

## Repository layout: one branch per game

`main` holds only the centralized `.github/workflows/` that orchestrate every game.
Each game's actual image source lives on its own long-lived branch:

| Branch | Contents |
| --- | --- |
| `main` | Centralized `update-*-version.yml` (scheduled) and `build-*-image.yml` (dispatch) workflows |
| `game/valheim` | Valheim `Dockerfile`, `etc/`, `scripts/`, `.valheim.env`, plus its own workflow copies |
| `game/terraria`, `game/factorio`, `game/minecraft` | Same shape for those games |

### No pull requests

This repo does not use PRs. Each `game/*` branch is effectively `main` for that game and
is committed to and pushed directly; `main` itself is the same. Do not open a PR, do not
create short-lived feature branches, and do not ask for review workflow — commit to the
relevant long-lived branch and push.

**Gotcha:** `build-valheim-image.yml` and `update-valheim-version.yml` exist on *both*
`main` and `game/valheim`, with deliberate differences. Changing one copy does not change
the other. When editing either, check whether the sibling copy needs the same change.

- `main:update-valheim-version.yml` has `schedule: cron '0 * * * *'` — this is the
  hourly auto-update. The `game/valheim` copy has the schedule deliberately removed
  (see commit `d0dad17`) so the job does not run twice.
- Both `build-valheim-image.yml` copies check out `ref: game/valheim`, so either can
  build the image; they differ only in which branch they are dispatched from.

## The auto-update chain

```
hourly cron on main
  └─> scripts/update-valheim-version.sh   (rewrites .valheim.env in place)
       └─> commit + push to game/valheim using secrets.BRANCH_PUSH_TOKEN
            └─> build-and-push-docker.yml on game/valheim (on: push)
                 └─> docker buildx build + push to Docker Hub
```

`BRANCH_PUSH_TOKEN` must be a PAT, not the default `GITHUB_TOKEN`: pushes made with
`GITHUB_TOKEN` do not trigger further workflow runs, which would break the final step.

GitHub disables scheduled workflows after 60 days without repository activity. If the
hourly bump silently stops, check that first.

## Version pins — `.valheim.env`

Four pins, all consumed as Docker build args and all fetched by
`scripts/update-valheim-version.sh`:

| Variable | Source |
| --- | --- |
| `VALHEIM_BUILD_ID` | `api.steamcmd.net/v1/info/896660` → `depots.branches.public.buildid` |
| `VALHEIM_LINUX_DEPOT_MANIFEST_ID` | depot `896661` (Valheim dedicated server Linux) manifest gid |
| `VALHEIM_SHARED_LINUX_DEPOT_MANIFEST_ID` | depot `1006` (shared Steamworks redist) manifest gid |
| `VALHEIM_PLUS_VERSION` | `tag_name` of the latest release of `Grantapher/ValheimPlus` |

Depot `1006` is shared across Steam apps and **can change without a Valheim build ID
bump**. The staleness check in `update-valheim-version.sh` therefore compares all four
pins; do not reduce it back to comparing only build ID and V+ version.

**The two manifest pins are metadata, not enforcement.** `etc/entry.sh` installs with
`steamcmd +app_update "$STEAMAPPID" validate`, which always fetches whatever the `public`
branch currently points at — the manifest IDs are never passed to SteamCMD. Commit
`62bc8a1` ("fix: fall back when valheim depot download fails") deliberately removed the
earlier `+download_depot <depot> <manifest>` + `rsync` approach because those depot
downloads were failing. Consequences to keep in mind:

- Image builds are **not** reproducible by manifest; two builds of the same tag can
  contain different game files.
- The manifest pins still matter for tag naming, drift detection, and as a record of what
  was current at build time, so keep them accurate.
- `STEAMCMD_UPDATE_ARGS` is the only supported way to pin or select a beta at runtime.
- Do not "fix" this by reintroducing `download_depot` without first confirming the depot
  download failure is gone; that regression is what `62bc8a1` addressed.

`VALHEIM_PLUS_VERSION` *is* enforced: `entry.sh` downloads that exact release tag's
`UnixServer.tar.gz` from `Grantapher/ValheimPlus`.

Read helpers: `scripts/get-valheim-build-id.sh`, `scripts/get-valheim-version.sh`.
The `ARG` defaults in the `Dockerfile` mirror these pins so a bare `docker build` with
no `--build-arg` still produces a current image; CI always passes them explicitly.

## Docker Hub

Images publish to **`martingwheeler/valheim`** (personal account). Previously
`servertimeio/valheim` — do not reintroduce that name.

Tags produced by every build:

- `martingwheeler/valheim:base`, `:latest`, `:<VALHEIM_BUILD_ID>` — `bookworm-base` target
- `martingwheeler/valheim:plus`, `:plus-<VALHEIM_BUILD_ID>-<VALHEIM_PLUS_VERSION>` — `bookworm-plus` target

The tag list is duplicated in `build`, `.github/workflows/build-and-push-docker.yml`,
and both copies of `build-valheim-image.yml`. Update all of them together.

Secrets used: `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`, `BRANCH_PUSH_TOKEN`.

## Image structure

`Dockerfile` has three stages, based on `cm2network/steamcmd:root`:

- `build_stage` — apt packages, copies `etc/entry.sh` and `etc/tinientry.sh`
- `bookworm-base` — env defaults, `USER`, `ENTRYPOINT ["tini", "-g", "--", "/home/steam/tinientry.sh"]`
- `bookworm-plus` — adds `VALHEIM_PLUS_VERSION`; V+ is downloaded at runtime by `entry.sh`

Conventions:

- Put runtime behavior in `etc/entry.sh` / `etc/tinientry.sh`, not in the `Dockerfile`.
- `tinientry.sh` injects `ADDITIONAL_ARGS` into `entry.sh`; new runtime flags go through
  that placeholder handling.
- Preserve existing env defaults when adding new ones, and document them in `README.md`.

## Runtime notes

- Steam query port is `SERVER_PORT + 1`; increment `SERVER_PORT` by 2 per instance.
- `:latest` and `:plus` persist worlds in different paths — `README.md` is authoritative.
- The container updates the game via SteamCMD on start, so a restart pulls updates.
- Default log path: `logs_output/outputlog_server.txt` (`SERVER_LOG_PATH`).

## Local commands

```bash
./build                              # builds both targets using .valheim.env
DOCKER_REPO=martingwheeler/valheim ./push
./scripts/update-valheim-version.sh  # rewrites .valheim.env; idempotent no-op when current
```

`.github/copilot-instructions.md` covers the same ground for Copilot; keep the two in sync.
