# Factorio Dedicated Server Docker Image

This repository builds a Docker image that runs the **Factorio** headless server. The container
downloads the official headless server, extracts the Linux binaries, auto-generates a save file if needed,
and provides convenient environment variables to configure `server-settings.json` without manual editing.

## Quick start

Build the image:

```sh
./build
# or
docker build --no-cache -t martingwheeler/factorio:latest .
```

Create a persistent directory for saves and configuration:

```sh
mkdir -p ~/factorio
chmod 777 ~/factorio
```

Run the server using a host bind mount (recommended); map the host folder to 
`/home/steam/factorio`, which is where the server stores saves and configuration:

**On Linux/macOS:**
```sh
docker run -d --name factorio-server \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -v ~/factorio:/home/steam/factorio \
  martingwheeler/factorio:latest
```

**On Windows with Git Bash:**
```bash
MSYS_NO_PATHCONV=1 docker run -d --name factorio-server \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -v ~/factorio:/home/steam/factorio \
  martingwheeler/factorio:latest
```

The container will automatically:
- Download the Factorio headless server (2.0.73 by default)
- Generate a `server-settings.json` file from environment variables
- Create an initial save file called `factorio-server.zip`
- Start the server in headless mode

Check logs with:
```sh
docker logs -f factorio-server
```

## Configuration via environment variables

The entry script creates `server-settings.json` based on environment variables (provided as `-e VAR=value` to `docker run`).

### Server identity & gameplay
```sh
FACTORIO_SERVER_NAME          # Server name (default: "Factorio Server")
FACTORIO_SERVER_DESCRIPTION   # Description (default: "Headless Factorio server")
FACTORIO_MAX_PLAYERS          # Max players, 0=unlimited (default: 0)
FACTORIO_GAME_PASSWORD        # Server password for joining (default: empty/none)
FACTORIO_PAUSE_WHEN_EMPTY     # Pause game when no players connected (default: true)
```

### Autosave & persistence
```sh
FACTORIO_AUTOSAVE_INTERVAL    # Autosave interval in minutes (default: 10)
FACTORIO_AUTOSAVE_SLOTS       # Number of autosave slots to keep (default: 5)
FACTORIO_SAVE_NAME            # Name of the save file (default: "factorio-server")
FACTORIO_CREATE_SAVE          # Auto-create save if missing (default: true)
```

### RCON (Remote Console)
```sh
FACTORIO_RCON_PASSWORD        # Password for RCON access (default: empty/disabled)
FACTORIO_RCON_PORT            # RCON port number (default: 27015)
```

### Optional logging & lists
```sh
FACTORIO_CONSOLE_LOG          # Path to console log file (default: empty)
FACTORIO_SERVER_WHITELIST     # Path to whitelist file (default: empty)
FACTORIO_SERVER_BANLIST       # Path to banlist file (default: empty)
FACTORIO_SERVER_ADMINLIST     # Path to adminlist file (default: empty)
```

### Advanced
```sh
FACTORIO_VERSION              # Server version to download (default: 2.0.73)
FACTORIO_URL                  # Custom download URL (default: official headless)
FACTORIO_REGENERATE_SETTINGS  # Force regenerate settings on each start (default: false)
ADDITIONAL_ARGS               # Extra CLI flags to pass to the server binary
```

## Usage examples

### Basic server with custom name and password:

```sh
docker run -d --name factorio-server \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -v ~/factorio:/home/steam/factorio \
  -e FACTORIO_SERVER_NAME="My Awesome Factory" \
  -e FACTORIO_GAME_PASSWORD="secret123" \
  -e FACTORIO_MAX_PLAYERS="10" \
  martingwheeler/factorio:latest
```

### With RCON enabled for remote administration:

```sh
docker run -d --name factorio-server \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -p 27015:27015/tcp \
  -v ~/factorio:/home/steam/factorio \
  -e FACTORIO_RCON_PASSWORD="admin123" \
  -e FACTORIO_SERVER_NAME="Factory with RCON" \
  martingwheeler/factorio:latest
```

### With custom autosave settings:

```sh
docker run -d --name factorio-server \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -v ~/factorio:/home/steam/factorio \
  -e FACTORIO_AUTOSAVE_INTERVAL="5" \
  -e FACTORIO_AUTOSAVE_SLOTS="10" \
  -e FACTORIO_PAUSE_WHEN_EMPTY="false" \
  martingwheeler/factorio:latest
```

### Interactive mode for debugging:

```sh
docker run --rm -it \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -v ~/factorio:/home/steam/factorio \
  martingwheeler/factorio:latest
```

## Persisting data

Mount a host directory or Docker volume at `/home/steam/factorio`. The server reads/writes:
- **Saves:** `~/factorio/saves/` — all `.zip` save files
- **Config:** `~/factorio/server-settings.json` — generated on first start
- **Logs:** `~/factorio/console_log.txt` (if `FACTORIO_CONSOLE_LOG` is set)

Make sure the `steam` user (UID 1000) has write permission:
```sh
chmod 777 ~/factorio
```

## Advanced use

### Run a shell for manual inspection:
```sh
docker run --rm -it --entrypoint /bin/bash martingwheeler/factorio:latest
```

### Use a specific save file:
```sh
# First, put your save in ~/factorio/saves/my-world.zip
docker run -d --name factorio-server \
  -p 34197:34197/tcp -p 34197:34197/udp \
  -v ~/factorio:/home/steam/factorio \
  -e FACTORIO_SAVE_NAME="my-world" \
  martingwheeler/factorio:latest
```

### Create a save with custom map generation settings:
Before starting the server, you can manually create a save with custom settings:
```sh
docker run --rm -it --entrypoint /bin/bash \
  -v ~/factorio:/home/steam/factorio \
  martingwheeler/factorio:latest

# Inside container:
cd /home/steam/factorio
./bin/x64/factorio --create saves/custom-seed.zip --map-gen-seed 12345
# Then start normally with FACTORIO_SAVE_NAME=custom-seed
```

## Environment info

- **Base image:** `cm2network/steamcmd:root` (steam user for file permissions)
- **Server version:** 2.0.73 headless (Linux 64-bit)
- **Default port:** 34197/tcp and 34197/udp (Factorio multiplayer)
- **RCON port:** 27015/tcp (optional, only if password set)
- **Working directory:** `/home/steam/factorio`

## Windows / Git-Bash considerations

When using Docker on Windows with Git-Bash or MSYS, **always prefix with `MSYS_NO_PATHCONV=1`** to prevent path translation issues:

```bash
# Correct:
MSYS_NO_PATHCONV=1 docker run -v ~/factorio:/home/steam/factorio …

# Also works: absolute Windows paths
docker run -v C:/Users/username/factorio:/home/steam/factorio …
```

---

For official Factorio server documentation, see: https://wiki.factorio.com/Multiplayer
