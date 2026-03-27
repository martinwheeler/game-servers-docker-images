# What is Valheim?
A brutal exploration and survival game for 1-10 players, set in a procedurally-generated purgatory inspired by Viking culture. Battle, build, and conquer your way to a saga worthy of Odin’s patronage!

>  [Valheim](https://store.steampowered.com/app/892970/Valheim/)

<img src="https://static.wikia.nocookie.net/valheim/images/4/4c/Logo_valheim.png" alt="logo" width="300"/></img>

# How to use this image

This image is a fork of [CM2Walki/Valheim](https://github.com/CM2Walki/Valheim) to add support for the [V+ Reforged](https://github.com/Grantapher/ValheimPlus) mod. The previous [Valheim Plus](https://github.com/valheimPlus/ValheimPlus) mod is no longer maintained.

The pinned dedicated-server build and V+ Reforged version for this branch live in `.valheim.env`.
You can inspect them with `./scripts/get-valheim-build-id.sh` and `./scripts/get-valheim-version.sh`.

## Hosting a simple game server

Running on the *host* interface (recommended):<br/>
```console
$ docker run -d --net=host --name=valheim-dedicated martingwheeler/valheim
```

Running using a bind mount for data persistence on container recreation:
```console
$ mkdir -p $(pwd)/valheim-data
$ chmod 777 $(pwd)/valheim-data # Makes sure the directory is writeable by the unprivileged container user
$ docker run -d --net=host -v $(pwd)/valheim-data:/home/steam/valheim-dedicated/ --name=valheim-dedicated martingwheeler/valheim
---
$ docker volume create valheim-plus-data # For valheim:plus - Create an additional world volume
$ docker run -d --net=host -v $(pwd)/valheim-data:/home/steam/valheim-dedicated/ -v valheim-plus-data:/home/steam/.config/unity3d/IronGate/Valheim/ --name=valheim-plus-dedicated martingwheeler/valheim:plus
```

Running multiple instances (increment SERVER_PORT by two, there is no way to overwrite the steam query port, it will always be SERVER_PORT + 1!):
```console
$ docker run -d --net=host -e SERVER_PORT=2458 --name=valheim-dedicated2 martingwheeler/valheim
```

**It's also recommended to use "--cpuset-cpus=" to limit the game server to a specific core & thread.**<br/>
**The container installs the Valheim dedicated-server build pinned in `.valheim.env` on startup.**

# Configuration
## Environment Variables
Feel free to overwrite these environment variables, using -e (--env): 
```dockerfile
SERVER_PORT=2456 (Game Port (tcp & udp); Steam Query Port (udp) will be SERVER_PORT + 1)
SERVER_PUBLIC=1
SERVER_WORLD_NAME="BraveNewWorld"
SERVER_PW="changeme"
SERVER_NAME="New \"${STEAMAPP}\" Server"
SERVER_LOG_PATH="logs_output/outputlog_server.txt"
SERVER_SAVE_DIR="Worlds"
SCREEN_QUALITY="Fastest"
SCREEN_WIDTH=640
SCREEN_HEIGHT=480
STEAMCMD_UPDATE_ARGS="" (Gets appended here: +app_update [appid] [STEAMCMD_UPDATE_ARGS]; Example: "validate")
ADDITIONAL_ARGS="" (Pass additional arguments to the server. Make sure to escape correctly!)
```

If you want to learn more about configuring a Valheim server check this [documentation](https://valheim.fandom.com/wiki/Hosting_Servers).

## Config
You can find the `adminlist.txt`, `bannedlist.txt` and `permittedlist.txt`:
- `/home/steam/valheim-dedicated/Worlds` for tag `valheim:latest`
- `/home/steam/.config/unity3d/IronGate/Valheim/Worlds` for tag `valheim:plus`

The world database files can be found in:
- `/home/steam/valheim-dedicated/Worlds/worlds` for tag `valheim:latest`
- `/home/steam/.config/unity3d/IronGate/Valheim/` for tag `valheim:plus`

# Image Variants:
The `valheim` images come in two flavors, each designed for a specific use case.

## `valheim:latest`
This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is a bare-minimum Valheim dedicated server containing no 3rd party plugins.<br/>

## `valheim:plus`
This is a specialized image. It contains the popular mod [V+ Reforged](https://github.com/Grantapher/ValheimPlus). 

Note: The game world is saved in a different directory in this tag, make sure to create an additional volume for world persistency across container recreations. See [#Hosting a simple game server](#hosting-a-simple-game-server) above.

## Automated version bumps

The `update-valheim-version` workflow checks the latest public Valheim dedicated-server build and
the latest V+ Reforged GitHub release, updates `.valheim.env` when either pin changes, and commits
the bump back to `game/valheim`.

# Contributors
[![Contributors Display](https://badges.pufler.dev/contributors/martinwheeler/valheim?size=50&padding=5&bots=false)](https://github.com/martinwheeler/valheim/graphs/contributors)
