#!/bin/bash
set -euo pipefail

API_URL="https://www.factorio.com/api/latest-releases"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .factorio.env ]; then
  echo ".factorio.env is missing" >&2
  exit 1
fi

response="$(curl -fsSL "${API_URL}")"

latest_version="$(
  python3 -c '
import json
import sys

data = json.load(sys.stdin)
stable = data.get("stable", {})
version = stable.get("headless")
if not version:
    raise SystemExit("Could not find stable.headless in Factorio latest releases API")
print(version)
' <<< "${response}"
)"

current_version="$(./scripts/get-factorio-version.sh)"

if [ "${current_version}" = "${latest_version}" ]; then
  echo "Factorio version already up to date (${current_version})"
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
    root / ".factorio.env": [
        (r"(?m)^FACTORIO_VERSION=.*$", f"FACTORIO_VERSION={version}"),
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

echo "Updated Factorio version from ${current_version} to ${latest_version}"
