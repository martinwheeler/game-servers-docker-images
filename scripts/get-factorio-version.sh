#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .factorio.env ]; then
  echo ".factorio.env is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source .factorio.env

if [ -z "${FACTORIO_VERSION:-}" ]; then
  echo "FACTORIO_VERSION is not set in .factorio.env" >&2
  exit 1
fi

printf '%s\n' "${FACTORIO_VERSION}"
