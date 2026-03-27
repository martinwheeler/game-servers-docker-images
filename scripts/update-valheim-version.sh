#!/bin/bash
set -euo pipefail

VALHEIM_PLUS_API_URL="https://api.github.com/repos/Grantapher/ValheimPlus/releases/latest"
VALHEIM_STEAM_API_URL="https://api.steamcmd.net/v1/info/896660"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .valheim.env ]; then
  echo ".valheim.env is missing" >&2
  exit 1
fi

valheim_plus_response="$(curl -fsSL "${VALHEIM_PLUS_API_URL}")"
steam_response="$(curl -fsSL "${VALHEIM_STEAM_API_URL}")"

latest_version="$(
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
tag = data.get("tag_name")
if not tag:
    raise SystemExit("Could not find tag_name in Valheim Plus latest release response")
print(tag)
' <<< "${valheim_plus_response}"
)"

current_version="$(./scripts/get-valheim-version.sh)"
current_build_id="$(./scripts/get-valheim-build-id.sh)"

steam_values="$(
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
app = data["data"]["896660"]
branches = app["depots"]["branches"]
print(branches["public"]["buildid"])
print(app["depots"]["896661"]["manifests"]["public"]["gid"])
print(app["depots"]["1006"]["manifests"]["public"]["gid"])
' <<< "${steam_response}"
)"

latest_build_id="$(sed -n '1p' <<< "${steam_values}")"
latest_linux_manifest_id="$(sed -n '2p' <<< "${steam_values}")"
latest_shared_linux_manifest_id="$(sed -n '3p' <<< "${steam_values}")"

if [ "${current_version}" = "${latest_version}" ] && [ "${current_build_id}" = "${latest_build_id}" ]; then
  echo "Valheim pins already up to date (build ${current_build_id}, V+ ${current_version})"
  exit 0
fi

export LATEST_VERSION="${latest_version}"
export LATEST_BUILD_ID="${latest_build_id}"
export LATEST_LINUX_DEPOT_MANIFEST_ID="${latest_linux_manifest_id}"
export LATEST_SHARED_LINUX_DEPOT_MANIFEST_ID="${latest_shared_linux_manifest_id}"

python3 <<'PY'
import os
import pathlib
import re

version = os.environ["LATEST_VERSION"]
build_id = os.environ["LATEST_BUILD_ID"]
linux_manifest_id = os.environ["LATEST_LINUX_DEPOT_MANIFEST_ID"]
shared_linux_manifest_id = os.environ["LATEST_SHARED_LINUX_DEPOT_MANIFEST_ID"]
root = pathlib.Path.cwd()

replacements = {
    root / ".valheim.env": [
        (r"(?m)^VALHEIM_BUILD_ID=.*$", f"VALHEIM_BUILD_ID={build_id}"),
        (r"(?m)^VALHEIM_LINUX_DEPOT_MANIFEST_ID=.*$", f"VALHEIM_LINUX_DEPOT_MANIFEST_ID={linux_manifest_id}"),
        (
            r"(?m)^VALHEIM_SHARED_LINUX_DEPOT_MANIFEST_ID=.*$",
            f"VALHEIM_SHARED_LINUX_DEPOT_MANIFEST_ID={shared_linux_manifest_id}",
        ),
        (r"(?m)^VALHEIM_PLUS_VERSION=.*$", f"VALHEIM_PLUS_VERSION={version}"),
    ],
}

for path, patterns in replacements.items():
    original = path.read_text()
    updated = original
    for pattern, replacement in patterns:
        updated, count = re.subn(pattern, replacement, updated)
        if count != 1:
            raise SystemExit(f"Expected exactly one match for {pattern!r} in {path}, got {count}")
    if updated != original:
        path.write_text(updated)
PY

echo "Updated Valheim build from ${current_build_id} to ${latest_build_id}"
echo "Updated Valheim Plus version from ${current_version} to ${latest_version}"
