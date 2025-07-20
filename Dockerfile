###########################################################
# Dockerfile that builds a Valheim Gameserver
###########################################################
FROM cm2network/steamcmd:root AS build_stage

LABEL maintainer="walentinlamonos@gmail.com"

ENV STEAMAPPID=896660
ENV STEAMAPP=valheim
ENV STEAMAPPDIR="${HOMEDIR}/${STEAMAPP}-dedicated"
ENV DLURL=https://raw.githubusercontent.com/CM2Walki/Valheim

COPY "etc/entry.sh" "${HOMEDIR}/entry.sh"
COPY "etc/tinientry.sh" "${HOMEDIR}/tinientry.sh"

RUN set -x \
  # Install, update & upgrade packages
  && apt-get update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  libatomic1 \
  wget \
  ca-certificates \
  lib32z1 \
  tini \
  libc6-dev \
  file \
  libpulse0 \
  libpulse-dev

RUN set -x \
  && mkdir -p "${STEAMAPPDIR}" \
  && chmod +x "${HOMEDIR}/entry.sh" "${HOMEDIR}/tinientry.sh" \
  && chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${HOMEDIR}/tinientry.sh" "${STEAMAPPDIR}" \
  # Clean up
  && rm -rf /var/lib/apt/lists/*

FROM build_stage AS bookworm-base

ENV SERVER_PORT=2456 \
  SERVER_PUBLIC=1 \
  SERVER_WORLD_NAME="BraveNewWorld" \
  SERVER_PW="changeme" \
  SERVER_NAME="New \"${STEAMAPP}\" Server" \
  SERVER_LOG_PATH="logs_output/outputlog_server.txt" \
  SERVER_SAVE_DIR="Worlds" \
  SCREEN_QUALITY="Fastest" \
  SCREEN_WIDTH=640 \
  SCREEN_HEIGHT=480 \
  ADDITIONAL_ARGS="" \
  STEAMCMD_UPDATE_ARGS=""

# Switch to user
USER ${USER}

WORKDIR ${HOMEDIR}

# Overwrite Stopsignal for graceful server exits
STOPSIGNAL SIGINT

ENTRYPOINT ["tini", "-g", "--", "/home/steam/tinientry.sh"]

# Expose ports
EXPOSE 2456/tcp \
  2456/udp \
  2467/udp

FROM bookworm-base AS bookworm-plus

ENV VALHEIM_PLUS_VERSION=0.9.16.2
