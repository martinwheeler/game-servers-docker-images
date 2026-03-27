###########################################################
# Dockerfile that builds a Factorio dedicated server image
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="hello@martinwheeler.com.au"

ARG FACTORIO_VERSION=2.0.76

# Factorio-only image: downloads the official headless server, extracts
# the Linux binaries and runs the 64-bit server binary.
ENV FACTORIO_VERSION="${FACTORIO_VERSION}" \
  FACTORIO_URL="https://www.factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64" \
  # server configuration (stored in server-settings.json)
  FACTORIO_SERVER_NAME="Factorio Server" \
  FACTORIO_SERVER_DESCRIPTION="Headless Factorio server" \
  FACTORIO_GAME_PASSWORD="" \
  FACTORIO_RCON_PASSWORD="" \
  FACTORIO_RCON_PORT="27015" \
  FACTORIO_MAX_PLAYERS="0" \
  FACTORIO_AUTOSAVE_INTERVAL="10" \
  FACTORIO_AUTOSAVE_SLOTS="5" \
  FACTORIO_PAUSE_WHEN_EMPTY="true" \
  # file paths for optional configuration/logging
  FACTORIO_CONSOLE_LOG="" \
  FACTORIO_SERVER_WHITELIST="" \
  FACTORIO_SERVER_BANLIST="" \
  FACTORIO_SERVER_ADMINLIST="" \
  # save file configuration
  FACTORIO_PORT="34197" \
  FACTORIO_SAVE_NAME="factorio-server" \
  FACTORIO_CREATE_SAVE="true" \
  FACTORIO_REGENERATE_SETTINGS="false" \
  # additional server options (command-line args)
  ADDITIONAL_ARGS=""

COPY "etc/entry.sh" "${HOMEDIR}/entry.sh"
COPY "etc/tinientry.sh" "${HOMEDIR}/tinientry.sh"

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends wget xz-utils ca-certificates tini \
  && chmod +x "${HOMEDIR}/entry.sh" "${HOMEDIR}/tinientry.sh" \
  && chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${HOMEDIR}/tinientry.sh" \
  && rm -rf /var/lib/apt/lists/*

# Switch to unprivileged steam user provided by base image
USER ${USER}

WORKDIR ${HOMEDIR}

# Overwrite Stopsignal for graceful server exits
STOPSIGNAL SIGINT

ENTRYPOINT ["tini", "-g", "--", "/home/steam/tinientry.sh"]

# Expose Factorio default ports
EXPOSE 34197/tcp \
  34197/udp
