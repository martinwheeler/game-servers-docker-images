FROM eclipse-temurin:21-jre-noble

LABEL maintainer="hello@martinwheeler.com.au"

ARG MINECRAFT_VERSION
ARG FORGE_VERSION
ARG RCON_CLI_VERSION=1.7.4

ENV MINECRAFT_VERSION="${MINECRAFT_VERSION}" \
  SERVER_SOFTWARE="Forge" \
  SERVER_SOFTWARE_FAMILY="forge" \
  SERVER_SOFTWARE_VERSION="${FORGE_VERSION}" \
  FORGE_VERSION="${FORGE_VERSION}" \
  SERVER_EXECUTABLE="/opt/minecraft/run.sh" \
  SERVER_LAUNCH_MODE="script" \
  JVM_ARGS_FILE="/opt/minecraft/user_jvm_args.txt" \
  CONTAINER_HOME="/home/minecraft" \
  SERVER_DIR="/data" \
  PUID="1000" \
  PGID="1000" \
  EULA="TRUE" \
  MEMORY="1G" \
  JAVA_OPTS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=40 -XX:G1MaxNewSizePercent=50 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=15 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=20 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true" \
  SERVER_PORT="25565" \
  LEVEL_NAME="world" \
  LEVEL_SEED="" \
  LEVEL_TYPE="minecraft:normal" \
  MOTD="A Forge Server" \
  MAX_PLAYERS="20" \
  MAX_BUILD_HEIGHT="319" \
  DIFFICULTY="easy" \
  GAMEMODE="survival" \
  FORCE_GAMEMODE="false" \
  HARDCORE="false" \
  ONLINE_MODE="true" \
  PVP="true" \
  SPAWN_PROTECTION="16" \
  WHITE_LIST="false" \
  ENABLE_COMMAND_BLOCK="false" \
  ENABLE_RCON="false" \
  RCON_PORT="25575" \
  VIEW_DISTANCE="10" \
  SIMULATION_DISTANCE="10" \
  ADDITIONAL_ARGS=""

COPY "etc/entry.sh" "/usr/local/bin/entry.sh"
COPY "etc/tinientry.sh" "/usr/local/bin/tinientry.sh"

RUN set -eux \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       bash ca-certificates curl gosu tini \
  && rm -rf /var/lib/apt/lists/* \
  && if id ubuntu >/dev/null 2>&1; then userdel -r ubuntu; fi \
  && groupadd -g 1000 minecraft \
  && useradd -m -d "${CONTAINER_HOME}" -u 1000 -g minecraft -s /bin/bash minecraft \
  && mkdir -p /opt/minecraft "${SERVER_DIR}" "${CONTAINER_HOME}" \
  && sed -i 's/\r$//' /usr/local/bin/entry.sh /usr/local/bin/tinientry.sh \
  && chmod +x /usr/local/bin/entry.sh /usr/local/bin/tinientry.sh \
  && case "$(uname -m)" in \
       x86_64) rcon_arch="amd64" ;; \
       aarch64) rcon_arch="arm64" ;; \
       armv7l) rcon_arch="armv7" ;; \
       *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
     esac \
  && curl -fsSL "https://github.com/itzg/rcon-cli/releases/download/${RCON_CLI_VERSION}/rcon-cli_${RCON_CLI_VERSION}_linux_${rcon_arch}.tar.gz" -o /tmp/rcon-cli.tgz \
  && tar -xzf /tmp/rcon-cli.tgz -C /tmp rcon-cli \
  && install -m 0755 /tmp/rcon-cli /usr/local/bin/rcon-cli \
  && rm -f /tmp/rcon-cli /tmp/rcon-cli.tgz \
  && installer_url="https://maven.minecraftforge.net/net/minecraftforge/forge/${MINECRAFT_VERSION}-${FORGE_VERSION}/forge-${MINECRAFT_VERSION}-${FORGE_VERSION}-installer.jar" \
  && curl -fsSL "${installer_url}" -o /tmp/forge-installer.jar \
  && java -jar /tmp/forge-installer.jar --installServer /opt/minecraft \
  && rm -f /tmp/forge-installer.jar \
  && chmod +x /opt/minecraft/run.sh \
  && : > "${JVM_ARGS_FILE}" \
  && chown -R minecraft:minecraft /opt/minecraft "${SERVER_DIR}" "${CONTAINER_HOME}"

WORKDIR /data

STOPSIGNAL SIGINT

ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/tinientry.sh"]

EXPOSE 25565/tcp \
  25565/udp \
  25575/tcp
