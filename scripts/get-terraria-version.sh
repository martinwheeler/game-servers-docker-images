#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .terraria.env ]; then
  echo ".terraria.env is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source .terraria.env

if [ -z "${TERRARIA_VERSION:-}" ]; then
  echo "TERRARIA_VERSION is not set in .terraria.env" >&2
  exit 1
fi

printf '%s\n' "${TERRARIA_VERSION}"
