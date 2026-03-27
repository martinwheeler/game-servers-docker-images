###########################################################
# Dockerfile that builds a Minecraft PaperMC server image
###########################################################
FROM eclipse-temurin:21-jre-alpine

LABEL maintainer="hello@martinwheeler.com.au"

ARG MINECRAFT_VERSION
ARG PAPER_BUILD

ENV MINECRAFT_VERSION=${MINECRAFT_VERSION} \
  PAPER_BUILD=${PAPER_BUILD} \
  PAPER_PROJECT="paper" \
  CONTAINER_HOME="/home/minecraft" \
  SERVER_DIR="/data" \
  EULA="FALSE" \
  MEMORY="1G" \
  JAVA_OPTS="" \
  SERVER_PORT="25565" \
  LEVEL_NAME="world" \
  MOTD="A PaperMC Server" \
  MAX_PLAYERS="20" \
  DIFFICULTY="easy" \
  GAMEMODE="survival" \
  ONLINE_MODE="true" \
  ENABLE_COMMAND_BLOCK="false" \
  VIEW_DISTANCE="10" \
  SIMULATION_DISTANCE="10" \
  ADDITIONAL_ARGS=""

COPY "etc/entry.sh" "/usr/local/bin/entry.sh"
COPY "etc/tinientry.sh" "/usr/local/bin/tinientry.sh"

RUN set -eux \
  && apk add --no-cache bash curl jq tini \
  && addgroup -S minecraft \
  && adduser -S -D -h "${CONTAINER_HOME}" -G minecraft minecraft \
  && mkdir -p /opt/papermc "${SERVER_DIR}" "${CONTAINER_HOME}" \
  && chmod +x /usr/local/bin/entry.sh /usr/local/bin/tinientry.sh \
  && build_metadata="$(curl -fsSL "https://fill.papermc.io/v3/projects/${PAPER_PROJECT}/versions/${MINECRAFT_VERSION}/builds")" \
  && download_url="$(printf '%s' "${build_metadata}" | jq -r --argjson build "${PAPER_BUILD}" '.[] | select(.id == $build and .channel == "STABLE") | .downloads["server:default"].url')" \
  && checksum="$(printf '%s' "${build_metadata}" | jq -r --argjson build "${PAPER_BUILD}" '.[] | select(.id == $build and .channel == "STABLE") | .downloads["server:default"].checksums.sha256')" \
  && if [ -z "${download_url}" ] || [ "${download_url}" = "null" ]; then echo "Could not resolve Paper download URL for Minecraft ${MINECRAFT_VERSION} build ${PAPER_BUILD}" >&2; exit 1; fi \
  && curl -fsSL "${download_url}" -o /opt/papermc/paper.jar \
  && echo "${checksum}  /opt/papermc/paper.jar" | sha256sum -c - \
  && chown -R minecraft:minecraft /opt/papermc "${SERVER_DIR}" "${CONTAINER_HOME}"

USER minecraft

WORKDIR /data

STOPSIGNAL SIGINT

ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/tinientry.sh"]

EXPOSE 25565/tcp \
  25565/udp
