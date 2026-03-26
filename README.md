# Terraria Dedicated Server Docker Image

This repository builds a Docker image that runs the **Terraria** dedicated server. The container
downloads the official server zip, extracts the Linux binaries, and provides convenient environment
variables and a generated `serverconfig.txt` so you can use the same configuration mechanisms as
the Windows instructions.

## Quick start

Pin your Terraria server version in `.terraria.env` and commit it:

```sh
cat > .terraria.env <<'EOF'
TERRARIA_VERSION=1456
EOF
```

Build the image:

```sh
./build
# will produce:
#  - martingwheeler/terraria:latest
#  - martingwheeler/terraria:${TERRARIA_VERSION}

# or manual build:
# docker build --no-cache \
#   --build-arg TERRARIA_VERSION=1456 \
#   -t martingwheeler/terraria:latest \
#   -t martingwheeler/terraria:1456 .
```

Create a persistent world directory and give it wide permissions:

```sh
mkdir -p ~/terraria-worlds
chmod 777 ~/terraria-worlds
```

Run the server using a host bind mount (recommended); map the host
folder to `/home/steam/terraria`, which is where the server writes its
world files and metadata:

```sh
docker run -d --name terraria-server \
  -p 7777:7777/tcp -p 7777:7777/udp \
  -v ~/terraria-worlds:/home/steam/terraria \
  -e TERRARIA_AUTOCREATE=2 \
  martingwheeler/terraria:latest
```

The container will automatically download/update the Terraria server on startup.

### Attached/interactive mode

To type commands during startup or respond to prompts run with `-it --rm` instead of `-d` and omit
`-e TERRARIA_AUTOCREATE` if you want to choose options manually.

## Configuration via environment variables

The entry script creates a `serverconfig.txt` based on the following environment variables
(provided as `-e VAR=value` to `docker run`). Any variable left unset is omitted from the file,
and the server will prompt if it still needs input.

```sh
TERRARIA_WORLD        # path or name of existing world file (.wld), e.g. MyWorld.wld
TERRARIA_PORT         # default 7777
TERRARIA_MAXPLAYERS   # maximum players
TERRARIA_PASSWORD     # server password (empty for none)
TERRARIA_WORLDNAME    # displayed name for the world
TERRARIA_AUTOCREATE   # 1=small,2=medium,3=large (creates world if missing)
TERRARIA_NOGUI        # any value will add the -nogui flag
ADDITIONAL_ARGS       # extra CLI flags appended after -config
```

Example with explicit port and password:

```sh
docker run --rm -it \
  -v ~/terraria-worlds:/home/steam/terraria \
  -e TERRARIA_PORT=7778 \
  -e TERRARIA_PASSWORD=secret \
  martingwheeler/terraria:latest
```

### Why use a config file?

The official server accepts `-config serverconfig.txt`; writing the file via env vars lets you
change settings without editing the container image or typing responses interactively. The
`entry.sh` script prints where it generated the file and always passes `-config` when running.

## Persisting data

Mount a host directory or Docker volume at `/home/steam/terraria`. The server runs from that
folder and writes worlds, metadata, and `favorites.json` there—make sure the `steam` user (UID 1000) has write permission. A host bind (`chmod 777`) avoids issues seen with named volumes.

## Advanced use

You can still bypass the entry script by running a shell
`docker run --rm -it --entrypoint /bin/bash martingwheeler/terraria:latest` and starting
`./TerrariaServer.bin.x86_64` yourself. Use this for debugging or custom startup logic.

---

_This README replaces the original Valheim documentation – the repo now focuses solely on Terraria._
