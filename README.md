# Minecraft PaperMC Docker Image

This repository builds a Docker image that runs a **Minecraft** server using **PaperMC**.
The image pins a Minecraft release and a Paper build separately, downloads that exact Paper jar
at image build time, and starts the server with a lightweight Java runtime.

## Quick start

Pin the current Paper release in `.minecraft.env` and commit it:

```sh
./scripts/update-minecraft-version.sh
```

Build the image:

```sh
./build
# will produce:
#  - servertimeio/minecraft:latest
#  - servertimeio/minecraft:${MINECRAFT_VERSION}-paper-${PAPER_BUILD}
```

Create a persistent server directory:

```sh
mkdir -p ~/minecraft-server
```

Run the server:

```sh
docker run -d --name minecraft-server \
  -p 25565:25565/tcp -p 25565:25565/udp \
  -e PUID="$(id -u)" -e PGID="$(id -g)" \
  -v ~/minecraft-server:/data \
  servertimeio/minecraft:latest
```

The server data lives in `/data`. On first start the container writes `eula.txt` and, if
one does not already exist, a basic `server.properties`.
The container starts as root long enough to ensure `/data` is owned by the configured runtime
UID/GID, then drops privileges before starting Paper. The recommended default on Linux is to pass
`PUID="$(id -u)"` and `PGID="$(id -g)"` so the container matches the owner of the bind mount.

## Version pinning

The image pin lives in `.minecraft.env`:

```sh
MINECRAFT_VERSION=1.21.11
PAPER_BUILD=127
```

`MINECRAFT_VERSION` tracks the Minecraft release line, and `PAPER_BUILD` pins the exact stable
Paper build used for the image.

## Configuration via environment variables

These environment variables are available at runtime:

```sh
EULA                 # default TRUE
MEMORY               # heap size for both -Xms and -Xmx, default 1G
JAVA_OPTS            # extra JVM flags
PUID                 # runtime user id, default 1000
PGID                 # runtime group id, default 1000
SERVER_PORT          # default 25565
LEVEL_NAME           # default world
MOTD                 # default "A PaperMC Server"
MAX_PLAYERS          # default 20
DIFFICULTY           # default easy
GAMEMODE             # default survival
FORCE_GAMEMODE       # default false
ONLINE_MODE          # default true
ENABLE_COMMAND_BLOCK # default false
VIEW_DISTANCE        # default 10
SIMULATION_DISTANCE  # default 10
ADDITIONAL_ARGS      # extra arguments appended after --nogui
```

If you already have a `server.properties` file in your mounted data directory, the container
will leave it in place and just start the server.

On Linux hosts, `PUID` and `PGID` should usually match the owner of your bind-mounted server
directory:

```sh
docker run -d --name minecraft-server \
  -p 25565:25565/tcp -p 25565:25565/udp \
  -e PUID="$(id -u)" -e PGID="$(id -g)" \
  -v ~/minecraft-server:/data \
  servertimeio/minecraft:latest
```

## Advanced use

You can open a shell in the image for debugging:

```sh
docker run --rm -it --entrypoint /bin/bash servertimeio/minecraft:latest
```
