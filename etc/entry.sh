#!/bin/bash
mkdir -p "${STEAMAPPDIR}" || true

install_with_app_update() {
  # Override SteamCMD launch arguments if necessary.
  # Used for subscribing to betas or for testing.
  if [ -z "$STEAMCMD_UPDATE_ARGS" ]; then
    bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" validate +quit
  else
    steamcmd_update_args=($STEAMCMD_UPDATE_ARGS)
    bash "${STEAMCMDDIR}/steamcmd.sh" +force_install_dir "$STEAMAPPDIR" +login anonymous +app_update "$STEAMAPPID" "${steamcmd_update_args[@]}" validate +quit
  fi
}

install_with_app_update

if [ ! -x "${STEAMAPPDIR}/valheim_server.x86_64" ]; then
  echo "Valheim server binary is missing after Steam install: ${STEAMAPPDIR}/valheim_server.x86_64" >&2
  exit 1
fi

sanitized_world_name="$(printf '%s' "${SERVER_WORLD_NAME}" | sed -E 's/[^A-Za-z0-9_-]+/_/g; s/^_+//; s/_+$//')"
if [ -z "${sanitized_world_name}" ]; then
  sanitized_world_name="BraveNewWorld"
fi
if [ "${sanitized_world_name}" != "${SERVER_WORLD_NAME}" ]; then
  echo "Sanitized SERVER_WORLD_NAME from '${SERVER_WORLD_NAME}' to '${sanitized_world_name}' for world file safety." >&2
  SERVER_WORLD_NAME="${sanitized_world_name}"
fi

# The bepinex start script has no -savedir, so worlds land in VALHEIM_SAVE_ROOT.
# A volume mounted there can still be root-owned on hosts that pre-created it, which
# would otherwise fail deep inside the server with an unreadable stack trace.
save_root="${VALHEIM_SAVE_ROOT:-${HOMEDIR}/.config/unity3d/IronGate/Valheim}"
if ! mkdir -p "${save_root}/worlds_local" 2>/dev/null || [ ! -w "${save_root}/worlds_local" ]; then
  echo "Save directory ${save_root}/worlds_local is not writable by $(id -un) (uid $(id -u))." >&2
  echo "Chown the mounted volume to 1000:1000 on the host and restart the container." >&2
  exit 1
fi

# A password shorter than 5 characters is rejected deep inside server startup
# ("Error bad password"), after which the server exits 0 and a restart policy turns
# that into a reboot loop. Decide up front instead. This build has no -nopassword flag:
# omitting -password works for a private server, but -public 1 always needs a real one.
password_args=()
if [ -n "${SERVER_PW}" ]; then
  if [ "${#SERVER_PW}" -lt 5 ]; then
    echo "SERVER_PW must be at least 5 characters; Valheim rejects shorter passwords." >&2
    exit 1
  fi
  if [ "${SERVER_NAME#*"${SERVER_PW}"}" != "${SERVER_NAME}" ] || [ "${SERVER_WORLD_NAME#*"${SERVER_PW}"}" != "${SERVER_WORLD_NAME}" ]; then
    echo "SERVER_PW must not appear inside SERVER_NAME or SERVER_WORLD_NAME; Valheim refuses to start." >&2
    exit 1
  fi
  password_args=(-password "${SERVER_PW}")
elif [ "${SERVER_PUBLIC}" = "1" ]; then
  echo "SERVER_PUBLIC=1 requires SERVER_PW (at least 5 characters). Set a password or run with SERVER_PUBLIC=0." >&2
  exit 1
fi

# We assume that if the valheim plus config is missing, that this is a fresh container
# if [ ! -f "${STEAMAPPDIR}/start_server_bepinex.sh" ]; then
# Are we in a valheim plus container?
if [ ! -z "$VALHEIM_PLUS_VERSION" ]; then
  wget --max-redirect=30 -qO- https://github.com/Grantapher/ValheimPlus/releases/download/"${VALHEIM_PLUS_VERSION}"/UnixServer.tar.gz | tar xvzf - -C "${STEAMAPPDIR}"
  chmod +x "${STEAMAPPDIR}/start_server_bepinex.sh"
  cp "${STEAMAPPDIR}/start_server_bepinex.sh" "${STEAMAPPDIR}/copy_start_server_bepinex.sh"
  # The upstream script ends in a hardcoded exec line and never forwards "$@", so the
  # only way to control the server arguments is to rewrite that line. Everything above
  # it (BepInEx doorstop env, LD_LIBRARY_PATH, SteamAppId) is kept as shipped.
  sed -E 's#^exec \./valheim_server\.x86_64 .*#exec ./valheim_server.x86_64 "$@"#' "${STEAMAPPDIR}/copy_start_server_bepinex.sh" >"${STEAMAPPDIR}/start_server_bepinex.sh"
  if ! grep -q 'exec ./valheim_server.x86_64 "$@"' "${STEAMAPPDIR}/start_server_bepinex.sh"; then
    echo "Could not patch the exec line of start_server_bepinex.sh; ValheimPlus upstream layout changed." >&2
    exit 1
  fi
fi
# fi

cd "${STEAMAPPDIR}"

if [ ! -z "$VALHEIM_PLUS_VERSION" ]; then
  # This is missing a couple of parameters, because the start_server_bepinex.sh doesn't support them
  # Are we in a valheim plus container?
  bash "start_server_bepinex.sh" -name "${SERVER_NAME}" \
    "${password_args[@]}" \
    -port "${SERVER_PORT}" \
    -world "${SERVER_WORLD_NAME}" \
    -public "${SERVER_PUBLIC}"
else
  "./valheim_server.x86_64" -batchmode \
    -nographics \
    -screen-width "${SCREEN_WIDTH}" \
    -screen-height "${SCREEN_HEIGHT}" \
    -screen-quality "${SCREEN_QUALITY}" \
    -logFile "${SERVER_LOG_PATH}" \
    -port "${SERVER_PORT}" \
    -name "${SERVER_NAME}" \
    -world "${SERVER_WORLD_NAME}" \
    "${password_args[@]}" \
    -public "${SERVER_PUBLIC}" \
    -savedir "${SERVER_SAVE_DIR}" \
    {{ADDITIONAL_ARGS}}
fi
