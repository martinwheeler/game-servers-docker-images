###########################################################
# Dockerfile that builds a Terraria dedicated server image
###########################################################
FROM cm2network/steamcmd:root

LABEL maintainer="hello@martinwheeler.com.au"

# Terraria-only image: downloads the official dedicated-server zip, extracts
# the Linux binaries and runs the 64-bit server binary.
ENV TERRARIA_VERSION=1455 \
  TERRARIA_URL="https://terraria.org/api/download/pc-dedicated-server/terraria-server-1455.zip" \
  # configuration vars (empty = prompt unless ADDITIONAL_ARGS overrides)
  TERRARIA_WORLD="Default" \
  TERRARIA_PORT="7777" \
  TERRARIA_MAXPLAYERS="16" \
  TERRARIA_PASSWORD="12356" \
  TERRARIA_WORLDNAME="" \
  TERRARIA_AUTOCREATE="2" \
  # set to any non-empty value to add -nogui flag on the command line
  TERRARIA_NOGUI="1" \
  ADDITIONAL_ARGS=""

COPY "etc/entry.sh" "${HOMEDIR}/entry.sh"
COPY "etc/tinientry.sh" "${HOMEDIR}/tinientry.sh"

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends wget unzip ca-certificates tini \
  && chmod +x "${HOMEDIR}/entry.sh" "${HOMEDIR}/tinientry.sh" \
  && chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${HOMEDIR}/tinientry.sh" \
  && rm -rf /var/lib/apt/lists/*

# Switch to unprivileged steam user provided by base image
USER ${USER}

WORKDIR ${HOMEDIR}

# Overwrite Stopsignal for graceful server exits
STOPSIGNAL SIGINT

ENTRYPOINT ["tini", "-g", "--", "/home/steam/tinientry.sh"]

# Expose Terraria default ports
EXPOSE 7777/tcp \
  7777/udp
