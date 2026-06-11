#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="${ROOT_DIR}/vendor"
ARCHIVE_NAME="libtorch-cxx11-abi-shared-with-deps-2.7.1+cu118.zip"
ARCHIVE_PATH="${VENDOR_DIR}/${ARCHIVE_NAME}"
ARCHIVE_URL="https://download.pytorch.org/libtorch/cu118/libtorch-cxx11-abi-shared-with-deps-2.7.1%2Bcu118.zip"

mkdir -p "${VENDOR_DIR}"

if [[ -s "${ARCHIVE_PATH}" ]]; then
  echo "LibTorch archive already exists: ${ARCHIVE_PATH}"
  exit 0
fi

curl -L --fail --http1.1 --retry 10 --retry-delay 2 \
  -o "${ARCHIVE_PATH}" \
  "${ARCHIVE_URL}"

echo "Downloaded ${ARCHIVE_PATH}"
