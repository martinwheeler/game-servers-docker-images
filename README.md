# Minecraft Docker Images

This repository now builds three Minecraft Java server images from the same shared runtime layer:

- `paper`
- `fabric`
- `forge`

Each loader has its own pinned version file, its own Dockerfile under `game/minecraft/<loader>/Dockerfile`,
and its own image tags so the Minecraft version and loader version stay visible in the tag.

## Repository structure

```sh
game/minecraft/paper/Dockerfile
game/minecraft/fabric/Dockerfile
game/minecraft/forge/Dockerfile
etc/entry.sh
etc/tinientry.sh
.minecraft.paper.env
.minecraft.fabric.env
.minecraft.forge.env
```

The entrypoint is shared. Loader-specific behavior is selected through environment variables baked into
each Dockerfile.

## Version pinning

Paper pins live in `.minecraft.paper.env`:

```sh
MINECRAFT_VERSION=1.21.11
PAPER_BUILD=127
```

Fabric pins live in `.minecraft.fabric.env`:

```sh
MINECRAFT_VERSION=1.21.11
FABRIC_LOADER_VERSION=0.16.10
FABRIC_INSTALLER_VERSION=1.0.3
```

Forge pins live in `.minecraft.forge.env`:

```sh
MINECRAFT_VERSION=1.21.11
FORGE_VERSION=61.0.3
```

That gives each loader a fully pinned tag:

- `servertimeio/minecraft:1.21.11-paper-127`
- `servertimeio/minecraft:1.21.11-fabric-loader-0.16.10-installer-1.0.3`
- `servertimeio/minecraft:1.21.11-forge-61.0.3`

It also gives each loader a moving alias within the same Minecraft line:

- `servertimeio/minecraft:1.21.11-paper`
- `servertimeio/minecraft:1.21.11-fabric`
- `servertimeio/minecraft:1.21.11-forge`

And a moving alias for the loader family:

- `servertimeio/minecraft:paper-latest`
- `servertimeio/minecraft:fabric-latest`
- `servertimeio/minecraft:forge-latest`

Avoid a shared `latest` tag unless you explicitly want one loader, such as Paper, to be the default.

## Build locally

Build all three images:

```sh
./build
```

Build just one loader:

```sh
./build paper
./build fabric
./build forge
```

Push the same tag set:

```sh
./push
./push paper
```

## Runtime configuration

All three images expose the same main runtime settings:

```sh
EULA                 # default TRUE
MEMORY               # heap size, default 1G
JAVA_OPTS            # extra JVM flags
PUID                 # runtime user id, default 1000
PGID                 # runtime group id, default 1000
SERVER_PORT          # default 25565
LEVEL_NAME           # default world
LEVEL_SEED           # default empty
LEVEL_TYPE           # default minecraft:normal
MOTD                 # loader-specific default
MAX_PLAYERS          # default 20
MAX_BUILD_HEIGHT     # default 319
DIFFICULTY           # default easy
GAMEMODE             # default survival
FORCE_GAMEMODE       # default false
HARDCORE             # default false
ONLINE_MODE          # default true
PVP                  # default true
SPAWN_PROTECTION     # default 16
WHITE_LIST           # default false
ENABLE_COMMAND_BLOCK # default false
VIEW_DISTANCE        # default 10
SIMULATION_DISTANCE  # default 10
ADDITIONAL_ARGS      # extra arguments appended to the launcher
```

Run the Paper image:

```sh
mkdir -p ~/minecraft-paper

docker run -d --name minecraft-paper \
  -p 25565:25565/tcp -p 25565:25565/udp \
  -e PUID="$(id -u)" -e PGID="$(id -g)" \
  -v ~/minecraft-paper:/data \
  servertimeio/minecraft:paper-latest
```

The same container contract applies to Fabric and Forge. Only the image tag changes.

## Version helpers

These helper scripts read the loader pin files:

```sh
./scripts/get-minecraft-version.sh paper
./scripts/get-minecraft-version.sh fabric
./scripts/get-minecraft-version.sh forge
./scripts/get-paper-build.sh
./scripts/get-fabric-loader-version.sh
./scripts/get-fabric-installer-version.sh
./scripts/get-forge-version.sh
```

`./scripts/update-minecraft-version.sh` still updates the Paper pins automatically. Fabric and Forge remain
manually pinned for now, which keeps those builds predictable until you decide how you want to source their
recommended versions.
