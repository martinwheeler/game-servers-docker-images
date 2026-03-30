#!/bin/bash
set -euo pipefail

PROJECT_API_URL="https://fill.papermc.io/v3/projects/paper"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.minecraft.paper.env"

cd "${ROOT_DIR}"

if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} is missing" >&2
  exit 1
fi

project_response="$(curl -fsSL "${PROJECT_API_URL}")"

latest_version="$(
  python3 -c '
import json
import re
import sys

data = json.load(sys.stdin)
versions = []

for branch_versions in data.get("versions", {}).values():
    for version in branch_versions:
        if re.fullmatch(r"\d+(?:\.\d+){1,2}", version):
            versions.append(tuple(int(part) for part in version.split(".")))

if not versions:
    raise SystemExit("Could not find a stable Minecraft version in the Paper API response")

print(".".join(str(part) for part in max(versions)))
' <<< "${project_response}"
)"

builds_response="$(curl -fsSL "${PROJECT_API_URL}/versions/${latest_version}/builds")"

latest_build="$(
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
stable_builds = [build["id"] for build in data if build.get("channel") == "STABLE"]
if not stable_builds:
    raise SystemExit("Could not find a stable Paper build for the latest Minecraft version")
print(max(stable_builds))
' <<< "${builds_response}"
)"

current_version="$(./scripts/get-minecraft-version.sh paper)"
current_build="$(./scripts/get-paper-build.sh)"

if [ "${current_version}" = "${latest_version}" ] && [ "${current_build}" = "${latest_build}" ]; then
  echo "Minecraft and Paper pins already up to date (${current_version}, build ${current_build})"
  exit 0
fi

export LATEST_VERSION="${latest_version}"
export LATEST_BUILD="${latest_build}"

python3 <<'PY'
import os
import pathlib
import re

version = os.environ["LATEST_VERSION"]
build = os.environ["LATEST_BUILD"]
root = pathlib.Path.cwd()

replacements = {
    root / ".minecraft.paper.env": [
        (r"(?m)^MINECRAFT_VERSION=.*$", f"MINECRAFT_VERSION={version}"),
        (r"(?m)^PAPER_BUILD=.*$", f"PAPER_BUILD={build}"),
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

echo "Updated Minecraft version from ${current_version} to ${latest_version}"
echo "Updated Paper build from ${current_build} to ${latest_build}"
