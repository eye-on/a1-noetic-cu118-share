#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo --preserve-env=HTTP_PROXY,HTTPS_PROXY,NO_PROXY,http_proxy,https_proxy,no_proxy \
    bash "$0" "$@"
fi

KEYRING=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
LIST=/etc/apt/sources.list.d/nvidia-container-toolkit.list
BROKEN_LIST=/etc/apt/sources.list.d/nvidia-container-toolki
TMP_KEY=/tmp/nvidia-container-toolkit.gpgkey
ARCH="$(dpkg --print-architecture)"
DOCKER_PROXY_CONF=/etc/systemd/system/docker.service.d/proxy.conf

if [[ -z "${HTTP_PROXY:-}" && -f "${DOCKER_PROXY_CONF}" ]]; then
  proxy_value="$(grep -Eo 'HTTP_PROXY=[^"]+' "${DOCKER_PROXY_CONF}" | head -n1 | cut -d= -f2- || true)"
  if [[ -n "${proxy_value}" ]]; then
    export HTTP_PROXY="${proxy_value}"
    export HTTPS_PROXY="${proxy_value}"
    export http_proxy="${proxy_value}"
    export https_proxy="${proxy_value}"
  fi
fi

if [[ -e "${BROKEN_LIST}" ]]; then
  mv "${BROKEN_LIST}" "${BROKEN_LIST}.bak"
fi

curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey -o "${TMP_KEY}"
gpg --dearmor -o "${KEYRING}" "${TMP_KEY}"
printf 'deb [signed-by=%s] https://nvidia.github.io/libnvidia-container/stable/deb/%s /\n' \
  "${KEYRING}" "${ARCH}" > "${LIST}"

apt-get update \
  -o Dir::Etc::sourcelist='sources.list.d/nvidia-container-toolkit.list' \
  -o Dir::Etc::sourceparts='-' \
  -o APT::Get::List-Cleanup='0'

apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

docker info --format '{{json .Runtimes}} {{.DefaultRuntime}}'
