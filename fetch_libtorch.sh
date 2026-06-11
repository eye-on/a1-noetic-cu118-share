#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR_DIR="${ROOT_DIR}/vendor"
ARCHIVE_NAME="libtorch-cxx11-abi-shared-with-deps-2.7.1+cu118.zip"
ARCHIVE_PATH="${VENDOR_DIR}/${ARCHIVE_NAME}"
ARCHIVE_URL="${LIBTORCH_URL:-https://download.pytorch.org/libtorch/cu118/libtorch-cxx11-abi-shared-with-deps-2.7.1%2Bcu118.zip}"
ARCHIVE_SHA256="${LIBTORCH_SHA256:-65a33ca2751af31c0a6ae8b6e8b727c242ae1c41d294da97471de9c95ecb5406}"

mkdir -p "${VENDOR_DIR}"

verify_archive() {
  local actual
  actual="$(sha256sum "${ARCHIVE_PATH}" | awk '{print $1}')"
  if [[ "${actual}" != "${ARCHIVE_SHA256}" ]]; then
    echo "Checksum mismatch for ${ARCHIVE_PATH}" >&2
    echo "expected: ${ARCHIVE_SHA256}" >&2
    echo "actual:   ${actual}" >&2
    return 1
  fi
}

if [[ -s "${ARCHIVE_PATH}" ]]; then
  verify_archive
  echo "LibTorch archive already exists and checksum matches: ${ARCHIVE_PATH}"
  exit 0
fi

curl -L --fail --http1.1 --retry 10 --retry-delay 2 \
  -o "${ARCHIVE_PATH}" \
  "${ARCHIVE_URL}"

verify_archive

echo "Downloaded ${ARCHIVE_PATH}"
