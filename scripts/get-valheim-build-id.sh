#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .valheim.env ]; then
  echo ".valheim.env is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source .valheim.env

if [ -z "${VALHEIM_BUILD_ID:-}" ]; then
  echo "VALHEIM_BUILD_ID is not set in .valheim.env" >&2
  exit 1
fi

printf '%s\n' "${VALHEIM_BUILD_ID}"
