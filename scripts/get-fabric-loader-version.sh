#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.minecraft.fabric.env"

cd "${ROOT_DIR}"

if [ ! -f "${ENV_FILE}" ]; then
  echo "${ENV_FILE} is missing" >&2
  exit 1
fi

# shellcheck disable=SC1091
source "${ENV_FILE}"

if [ -z "${FABRIC_LOADER_VERSION:-}" ]; then
  echo "FABRIC_LOADER_VERSION is not set in ${ENV_FILE}" >&2
  exit 1
fi

printf '%s\n' "${FABRIC_LOADER_VERSION}"
