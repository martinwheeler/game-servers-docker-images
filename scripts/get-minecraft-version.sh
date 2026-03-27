#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

if [ ! -f .minecraft.env ]; then
  echo ".minecraft.env is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source .minecraft.env

if [ -z "${MINECRAFT_VERSION:-}" ]; then
  echo "MINECRAFT_VERSION is not set in .minecraft.env" >&2
  exit 1
fi

printf '%s\n' "${MINECRAFT_VERSION}"
