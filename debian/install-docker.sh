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
work_tmp="$(mktemp -d)"
source_backup=
source_published=0
source_publication_started=0
source_state() {
    sudo sh -eu -c '
        if [ -d "$1" ]; then printf directory;
        elif [ -e "$1" ] || [ -L "$1" ]; then printf present;
        else printf absent; fi
    ' sh "$1"
}
cleanup() {
    local status=$? source_name state restore_failed=0
    if [[ -n "$source_backup" ]]; then
        if ((source_published == 0)); then
            # The rename may have completed before a signal interrupted its caller.
            if ((source_publication_started)); then
                sudo rm -f -- /etc/apt/sources.list.d/docker.list || restore_failed=1
            fi
            for source_name in docker.list docker.sources; do
                if state="$(source_state "$source_backup/$source_name")"; then
                    case "$state" in
                        present) sudo mv -fT "$source_backup/$source_name" "/etc/apt/sources.list.d/$source_name" || restore_failed=1 ;;
                        absent) ;;
                        *) restore_failed=1 ;;
                    esac
                else
                    restore_failed=1
                fi
            done
        fi
        if ((restore_failed)); then
            echo "[ERROR] Could not restore Docker sources; backups retained at $source_backup" >&2
            status=1
        elif ((source_published)); then
            sudo rm -rf -- "$source_backup" || status=1
        else
            sudo rm -f -- "$source_backup/replacement" || status=1
            # Never recursively discard originals if a privileged check failed.
            sudo rmdir -- "$source_backup" || status=1
        fi
    fi
    rm -rf -- "$work_tmp"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
source_backup="$(sudo mktemp -d /etc/apt/sources.list.d/.docker-backup.XXXXXX)"
# Hide stale sources from APT, retaining the original inodes (including symlinks).
for source_name in docker.list docker.sources; do
    source_path="/etc/apt/sources.list.d/$source_name"
    state="$(source_state "$source_path")"
    case "$state" in
        present) sudo mv -T "$source_path" "$source_backup/$source_name" ;;
        absent) ;;
        *) echo "[ERROR] Refusing Docker source with state '$state': $source_path" >&2; exit 1 ;;
    esac
done
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
key_download="$work_tmp/key-download"
key_tmp="$work_tmp/key"
source_tmp="$work_tmp/source"
curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$key_download" "https://download.docker.com/linux/${PLATFORM_ID}/gpg"
verify_openpgp_fingerprint "$key_download" "$DOCKER_KEY_FINGERPRINT"
gpg --batch --dearmor <"$key_download" >"$key_tmp"
sudo install -m 0644 "$key_tmp" /etc/apt/keyrings/docker.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/%s %s stable\n' \
    "$(dpkg --print-architecture)" "$PLATFORM_ID" "$PLATFORM_CODENAME" >"$source_tmp"
sudo install -m 0644 "$source_tmp" "$source_backup/replacement"
source_publication_started=1
sudo mv -fT "$source_backup/replacement" /etc/apt/sources.list.d/docker.list
source_published=1
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
