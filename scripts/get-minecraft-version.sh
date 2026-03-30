#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VARIANT="${1:-paper}"
ENV_FILE="${ROOT_DIR}/.minecraft.${VARIANT}.env"

cd "${ROOT_DIR}"

if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "${ENV_FILE}"

if [ -z "${MINECRAFT_VERSION:-}" ]; then
  echo "MINECRAFT_VERSION is not set in ${ENV_FILE}" >&2
  exit 1
fi

printf '%s\n' "${MINECRAFT_VERSION}"
