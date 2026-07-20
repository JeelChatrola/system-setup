#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/platform.sh
source "$SCRIPT_DIR/../lib/platform.sh"
# shellcheck source=../lib/supply-chain.sh
source "$SCRIPT_DIR/../lib/supply-chain.sh"

DOCKER_KEY_FINGERPRINT=9DC858229FC7DD38854AE2D88D81803C0EBFCD88

echo "[*] Ensuring Docker Engine and Compose are installed..."
command -v apt-get >/dev/null 2>&1 || { echo "[ERROR] This script requires apt-get" >&2; exit 1; }

detect_platform
validate_platform "$PLATFORM_ID" "$PLATFORM_VERSION" "$PLATFORM_CODENAME" "$PLATFORM_ARCH" docker

echo "[*] Converging Docker's official repository and packages..."
# A stale source can make even the dependency update fail. Remove both source
# forms owned by this installer before consulting APT, then recreate one list.
sudo rm -f /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker.sources
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
key_download="$(mktemp)"
key_tmp="$(mktemp)"
source_tmp="$(mktemp)"
trap 'rm -f "$key_download" "$key_tmp" "$source_tmp"' EXIT
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$key_download" "https://download.docker.com/linux/${PLATFORM_ID}/gpg"
verify_openpgp_fingerprint "$key_download" "$DOCKER_KEY_FINGERPRINT"
gpg --batch --dearmor <"$key_download" >"$key_tmp"
sudo install -m 0644 "$key_tmp" /etc/apt/keyrings/docker.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/%s %s stable\n' \
    "$(dpkg --print-architecture)" "$PLATFORM_ID" "$PLATFORM_CODENAME" >"$source_tmp"
sudo install -m 0644 "$source_tmp" /etc/apt/sources.list.d/docker.list
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

if platform_has_systemd; then
    sudo systemctl enable --now docker
fi

if [[ "${SYSTEM_SETUP_ADD_DOCKER_GROUP:-0}" == 1 ]]; then
    target_user="${SYSTEM_SETUP_TARGET_USER:-$(id -un)}"
    [[ -n "$target_user" && "$target_user" != root ]] || {
        echo "[ERROR] Cannot determine a non-root user for Docker group membership" >&2
        exit 1
    }
    echo "[WARN] Adding $target_user to the docker group grants root-equivalent host access."
    sudo usermod -aG docker "$target_user"
    echo "[WARN] Log out and back in before using Docker without sudo."
else
    echo "[INFO] Docker group membership was not changed. Use --add-docker-group only if root-equivalent access is acceptable."
fi

command -v docker >/dev/null 2>&1 || { echo "[ERROR] Docker CLI is unavailable after installation" >&2; exit 1; }
docker --version
docker compose version
sudo docker info >/dev/null
echo "[OK] Docker Engine and Compose are available"
