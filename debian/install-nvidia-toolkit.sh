#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/platform.sh
source "$SCRIPT_DIR/../lib/platform.sh"
# shellcheck source=../lib/supply-chain.sh
source "$SCRIPT_DIR/../lib/supply-chain.sh"
# shellcheck source=../lib/repository-data.sh
source "$SCRIPT_DIR/../lib/repository-data.sh"

NVIDIA_KEY_FINGERPRINT=C95B321B61E88C1809C4F759DDCAE044F796ECB0

echo "[*] Ensuring NVIDIA Container Toolkit is configured..."
command -v apt-get >/dev/null 2>&1 || { echo "[ERROR] This script requires apt-get" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "[ERROR] Docker must be installed first" >&2; exit 1; }

detect_platform
validate_platform "$PLATFORM_ID" "$PLATFORM_VERSION" "$PLATFORM_CODENAME" "$PLATFORM_ARCH" nvidia

if command -v lspci >/dev/null 2>&1 && ! lspci | grep -qi nvidia; then
    if [[ "${SYSTEM_SETUP_YES:-0}" != 1 ]]; then
        read -r -p "No NVIDIA GPU detected. Continue anyway? [y/N]: " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || exit 1
    else
        echo "[WARN] No NVIDIA GPU detected; continuing because --yes was supplied."
    fi
fi

if ! command -v nvidia-ctk >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT
    curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
        --output "$temp_dir/key" https://nvidia.github.io/libnvidia-container/gpgkey
    verify_openpgp_fingerprint "$temp_dir/key" "$NVIDIA_KEY_FINGERPRINT"
    curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
        --output "$temp_dir/repository.list" https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list
    validate_nvidia_repository_file "$temp_dir/repository.list"
    gpg --batch --dearmor <"$temp_dir/key" >"$temp_dir/key.gpg"
    printf '%s\n' \
        "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" \
        >"$temp_dir/signed.list"
    sudo install -m 0644 "$temp_dir/key.gpg" /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    sudo install -m 0644 "$temp_dir/signed.list" /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
fi

daemon_json=/etc/docker/daemon.json
if [[ "${SYSTEM_SETUP_TEST_MODE:-0}" == 1 && -n "${SYSTEM_SETUP_DOCKER_DAEMON_JSON:-}" ]]; then
    daemon_json="$SYSTEM_SETUP_DOCKER_DAEMON_JSON"
fi
before="missing"
[[ ! -e "$daemon_json" ]] || before="$(sudo sha256sum "$daemon_json" | cut -d' ' -f1)"
sudo nvidia-ctk runtime configure --runtime=docker
after="missing"
[[ ! -e "$daemon_json" ]] || after="$(sudo sha256sum "$daemon_json" | cut -d' ' -f1)"
if [[ "$before" != "$after" ]] && platform_has_systemd; then
    sudo systemctl restart docker
fi

nvidia-ctk --version
sudo docker info >/dev/null
echo "[OK] NVIDIA Container Toolkit is configured for Docker"
