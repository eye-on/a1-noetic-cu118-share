#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${ROOT_DIR}/fetch_libtorch.sh"
docker compose -f "${ROOT_DIR}/docker-compose.yml" build
