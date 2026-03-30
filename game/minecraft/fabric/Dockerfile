FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="hello@martinwheeler.com.au"

ARG MINECRAFT_VERSION
ARG FABRIC_LOADER_VERSION
ARG FABRIC_INSTALLER_VERSION

ENV MINECRAFT_VERSION="${MINECRAFT_VERSION}" \
  SERVER_SOFTWARE="Fabric" \
  SERVER_SOFTWARE_FAMILY="fabric" \
  SERVER_SOFTWARE_VERSION="${FABRIC_LOADER_VERSION}" \
  FABRIC_LOADER_VERSION="${FABRIC_LOADER_VERSION}" \
  FABRIC_INSTALLER_VERSION="${FABRIC_INSTALLER_VERSION}" \
  SERVER_EXECUTABLE="/opt/minecraft/server.jar" \
  SERVER_LAUNCH_MODE="jar" \
  SERVER_NOGUI_FLAG="nogui" \
  CONTAINER_HOME="/home/minecraft" \
  SERVER_DIR="/data" \
  PUID="1000" \
  PGID="1000" \
  EULA="TRUE" \
  MEMORY="1G" \
  JAVA_OPTS="" \
  SERVER_PORT="25565" \
  LEVEL_NAME="world" \
  LEVEL_SEED="" \
  LEVEL_TYPE="minecraft:normal" \
  MOTD="A Fabric Server" \
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
  VIEW_DISTANCE="10" \
  SIMULATION_DISTANCE="10" \
  ADDITIONAL_ARGS=""

COPY "etc/entry.sh" "/usr/local/bin/entry.sh"
COPY "etc/tinientry.sh" "/usr/local/bin/tinientry.sh"

RUN set -eux \
  && apk add --no-cache bash curl su-exec tini \
  && addgroup -g 1000 -S minecraft \
  && adduser -S -D -h "${CONTAINER_HOME}" -G minecraft -u 1000 minecraft \
  && mkdir -p /opt/minecraft "${SERVER_DIR}" "${CONTAINER_HOME}" \
  && sed -i 's/\r$//' /usr/local/bin/entry.sh /usr/local/bin/tinientry.sh \
  && chmod +x /usr/local/bin/entry.sh /usr/local/bin/tinientry.sh \
  && curl -fsSL "https://meta.fabricmc.net/v2/versions/loader/${MINECRAFT_VERSION}/${FABRIC_LOADER_VERSION}/${FABRIC_INSTALLER_VERSION}/server/jar" -o "${SERVER_EXECUTABLE}" \
  && chown -R minecraft:minecraft /opt/minecraft "${SERVER_DIR}" "${CONTAINER_HOME}"

WORKDIR /data

STOPSIGNAL SIGINT

ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/tinientry.sh"]

EXPOSE 25565/tcp \
  25565/udp
