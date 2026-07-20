#!/bin/bash
# Install Tailscale as a system service on Debian-based hosts.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/platform.sh
source "$SCRIPT_DIR/../lib/platform.sh"
# shellcheck source=../lib/supply-chain.sh
source "$SCRIPT_DIR/../lib/supply-chain.sh"
# shellcheck source=../lib/repository-data.sh
source "$SCRIPT_DIR/../lib/repository-data.sh"

TAILSCALE_KEY_FINGERPRINT=2596A99EAAB33821893C0A79458CA832957F5868

if ! command -v apt-get >/dev/null 2>&1; then
    echo "[ERROR] This script is for Debian-based systems only" >&2
    exit 1
fi

detect_platform
validate_platform "$PLATFORM_ID" "$PLATFORM_VERSION" "$PLATFORM_CODENAME" "$PLATFORM_ARCH" tailscale

KEYRING=/usr/share/keyrings/tailscale-archive-keyring.gpg
SOURCE_LIST=/etc/apt/sources.list.d/tailscale.list
PACKAGE_BASE_URL="https://pkgs.tailscale.com/stable/${PLATFORM_ID}/${PLATFORM_CODENAME}"
TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[*] Installing Tailscale from its signed APT repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -d -m 0755 /usr/share/keyrings

curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$TEMP_DIR/tailscale-archive-keyring.gpg" \
    "$PACKAGE_BASE_URL.noarmor.gpg"
verify_openpgp_fingerprint "$TEMP_DIR/tailscale-archive-keyring.gpg" "$TAILSCALE_KEY_FINGERPRINT"

curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$TEMP_DIR/tailscale.list" \
    "$PACKAGE_BASE_URL.tailscale-keyring.list"
validate_tailscale_repository_file "$TEMP_DIR/tailscale.list" "$PLATFORM_ID" "$PLATFORM_CODENAME"
sudo install -m 0644 "$TEMP_DIR/tailscale-archive-keyring.gpg" "$KEYRING"
sudo install -m 0644 "$TEMP_DIR/tailscale.list" "$SOURCE_LIST"

sudo apt-get update
sudo apt-get install -y tailscale
sudo systemctl enable --now tailscaled

# Required before this host can advertise default routes as an exit node.
cat >"$TEMP_DIR/99-tailscale.conf" <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sudo install -m 0644 "$TEMP_DIR/99-tailscale.conf" /etc/sysctl.d/99-tailscale.conf
sudo sysctl --system

echo "[OK] Tailscale is installed and tailscaled is enabled."
echo "[INFO] Authentication and exit-node advertisement are intentionally manual."
echo "[INFO] Run: sudo tailscale up"
echo "[INFO] Then run: sudo tailscale set --advertise-exit-node"
echo "[INFO] Approve this machine as an exit node in the Tailscale admin console."
