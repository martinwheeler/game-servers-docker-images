#!/bin/bash
set -e

# Simple Factorio server install + run script for the container
# The Factorio binary reads/writes saves and config files in the data directory
# (which is ${HOMEDIR}/factorio).  mount this folder from the host to
# persist saves and server configuration.
mkdir -p "${HOMEDIR}/factorio" "${HOMEDIR}/factorio/saves" "${HOMEDIR}/factorio/config" || true

# Ensure permissions are correct on the data directories
chmod -R 755 "${HOMEDIR}/factorio" 2>/dev/null || true
chmod -R u+w "${HOMEDIR}/factorio" 2>/dev/null || true
# make sure steam user owns it (especially if using a named volume)
chown -R "${USER}:${USER}" "${HOMEDIR}/factorio" 2>/dev/null || true

cd "${HOMEDIR}"

# Defaults (can be overridden via ENV)
if [ -z "${FACTORIO_VERSION}" ]; then
  FACTORIO_VERSION=2.0.73
fi
if [ -z "${FACTORIO_URL}" ]; then
  FACTORIO_URL="https://www.factorio.com/get-download/${FACTORIO_VERSION}/headless/linux64"
fi
if [ -z "${FACTORIO_PORT}" ]; then
  FACTORIO_PORT=34197
fi
if [ -z "${FACTORIO_SAVE_NAME}" ]; then
  FACTORIO_SAVE_NAME="factorio-server"
fi
if [ -z "${FACTORIO_CREATE_SAVE}" ]; then
  FACTORIO_CREATE_SAVE="true"
fi

echo "Downloading Factorio headless server from ${FACTORIO_URL}"
wget -qO factorio.tar.xz "${FACTORIO_URL}"
tar -xJf factorio.tar.xz -C "${HOMEDIR}"
chmod +x "${HOMEDIR}/factorio/bin/x64/factorio"
rm -f factorio.tar.xz

cd "${HOMEDIR}/factorio"

# Ensure data directory structure exists
mkdir -p data
mkdir -p saves

# Generate server-settings.json from environment variables
# This allows users to configure the server without modifying the JSON directly
generate_server_settings() {
  local settings_file="$1"
  
  # Set defaults for common configuration options
  local server_name="${FACTORIO_SERVER_NAME:-Factorio Server}"
  local server_description="${FACTORIO_SERVER_DESCRIPTION:-Headless Factorio server}"
  local game_password="${FACTORIO_GAME_PASSWORD:-}"
  local max_players="${FACTORIO_MAX_PLAYERS:-0}"
  local rcon_password="${FACTORIO_RCON_PASSWORD:-}"
  local rcon_port="${FACTORIO_RCON_PORT:-27015}"
  local autosave_interval="${FACTORIO_AUTOSAVE_INTERVAL:-10}"
  local autosave_slots="${FACTORIO_AUTOSAVE_SLOTS:-5}"
  local pause_when_empty="${FACTORIO_PAUSE_WHEN_EMPTY:-true}"
  local console_log="${FACTORIO_CONSOLE_LOG:-}"
  local server_whitelist="${FACTORIO_SERVER_WHITELIST:-}"
  local server_banlist="${FACTORIO_SERVER_BANLIST:-}"
  local server_adminlist="${FACTORIO_SERVER_ADMINLIST:-}"
  
  # Build password JSON entries (only if non-empty), each with proper escaping
  local game_password_line=""
  if [ -n "$game_password" ]; then
    game_password_line="  \"game_password\": \"${game_password//\\/\\\\}\"," 
  fi
  
  local rcon_password_line=""
  if [ -n "$rcon_password" ]; then
    rcon_password_line="  \"rcon_password\": \"${rcon_password//\\/\\\\}\","
  fi
  
  local rcon_port_line=""
  if [ -n "$rcon_password" ]; then
    rcon_port_line="  \"rcon_port\": ${rcon_port},"
  fi
  
  # Build optional file path lines
  local console_log_line=""
  if [ -n "$console_log" ]; then
    console_log_line="  \"console_log\": \"${console_log}\","
  fi
  local whitelist_line=""
  if [ -n "$server_whitelist" ]; then
    whitelist_line="  \"whitelist\": \"${server_whitelist}\","
  fi
  local banlist_line=""
  if [ -n "$server_banlist" ]; then
    banlist_line="  \"banlist\": \"${server_banlist}\","
  fi
  local adminlist_line=""
  if [ -n "$server_adminlist" ]; then
    adminlist_line="  \"adminlist\": \"${server_adminlist}\","
  fi
  
  # Create the JSON file with all fields properly formatted
  cat > "$settings_file" <<-EOF
{
  "name": "${server_name}",
  "description": "${server_description}",
  "tags": ["game"],
  "visibility": {
    "public": false,
    "lan": true
  },
  "token": "",
$([ -n "$game_password_line" ] && echo "$game_password_line")
$([ -n "$rcon_password_line" ] && echo "$rcon_password_line")
$([ -n "$rcon_port_line" ] && echo "$rcon_port_line")
$([ -n "$console_log_line" ] && echo "$console_log_line")
$([ -n "$whitelist_line" ] && echo "$whitelist_line")
$([ -n "$banlist_line" ] && echo "$banlist_line")
$([ -n "$adminlist_line" ] && echo "$adminlist_line")
  "require_user_verification": true,
  "max_players": ${max_players},
  "afk_autokick_interval": 0,
  "autosave_interval": ${autosave_interval},
  "autosave_slots": ${autosave_slots},
  "keep_alive_interval": 60,
  "maximum_segmentation": 0,
  "maximum_upload_size": 100,
  "minimum_segment_size": 25,
  "pause_when_empty": ${pause_when_empty},
  "per_player_crafting_speeds": false
}
EOF
}

# Create server-settings.json if it doesn't exist, or regenerate if FACTORIO_REGENERATE_SETTINGS is set
if [ ! -f "server-settings.json" ] || [ "$FACTORIO_REGENERATE_SETTINGS" = "true" ]; then
  echo "Generating server-settings.json..."
  generate_server_settings "server-settings.json"
else
  echo "Using existing server-settings.json"
fi

# Check if a save file exists
SAVE_FILE="saves/${FACTORIO_SAVE_NAME}.zip"
if [ ! -f "$SAVE_FILE" ]; then
  if [ "$FACTORIO_CREATE_SAVE" = "true" ]; then
    echo "Creating new save file: $SAVE_FILE"
    ./bin/x64/factorio --create "$SAVE_FILE"
  else
    echo "ERROR: Save file $SAVE_FILE does not exist and FACTORIO_CREATE_SAVE is not enabled"
    exit 1
  fi
fi

# Build the command to run the server
cmd=("./bin/x64/factorio" "--start-server" "$SAVE_FILE" "--server-settings" "server-settings.json")

# append any additional args last
if [ -n "$ADDITIONAL_ARGS" ]; then
  # shellcheck disable=SC2206
  cmd+=( $ADDITIONAL_ARGS )
fi

echo "Starting Factorio server with save: $SAVE_FILE"
"${cmd[@]}"
