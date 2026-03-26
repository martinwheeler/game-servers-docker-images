#!/bin/bash
set -euo pipefail

API_URL="https://terraria.org/api/get/dedicated-servers-names"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .terraria.env ]; then
  echo ".terraria.env is missing" >&2
  exit 1
fi

response="$(curl -fsSL "${API_URL}")"

latest_zip="$(
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
if not isinstance(data, list) or not data:
    raise SystemExit("Unexpected API response")
print(data[0])
' <<< "${response}"
)"

latest_version="$(sed -n 's/^terraria-server-\([0-9][0-9]*\)\.zip$/\1/p' <<< "${latest_zip}")"
if [ -z "${latest_version}" ]; then
  echo "Could not extract Terraria desktop version from API response: ${latest_zip}" >&2
  exit 1
fi

current_version="$(./scripts/get-terraria-version.sh)"

if [ "${current_version}" = "${latest_version}" ]; then
  echo "Terraria version already up to date (${current_version})"
  exit 0
fi

export LATEST_VERSION="${latest_version}"

python3 <<'PY'
import os
import pathlib
import re

version = os.environ["LATEST_VERSION"]
root = pathlib.Path.cwd()

replacements = {
    root / ".terraria.env": [
        (r"(?m)^TERRARIA_VERSION=\d+$", f"TERRARIA_VERSION={version}"),
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

echo "Updated Terraria version from ${current_version} to ${latest_version}"
