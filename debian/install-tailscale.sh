#!/bin/bash
# Install Tailscale as a system service on Debian-based hosts.

set -euo pipefail

if ! command -v apt-get >/dev/null 2>&1; then
    echo "[ERROR] This script is for Debian-based systems only" >&2
    exit 1
fi

. /etc/os-release

if [[ "${ID:-}" != "debian" && "${ID:-}" != "ubuntu" ]] || [[ -z "${VERSION_CODENAME:-}" ]]; then
    echo "[ERROR] Unsupported distribution: ${PRETTY_NAME:-unknown}" >&2
    exit 1
fi

KEYRING=/usr/share/keyrings/tailscale-archive-keyring.gpg
SOURCE_LIST=/etc/apt/sources.list.d/tailscale.list
PACKAGE_BASE_URL="https://pkgs.tailscale.com/stable/${ID}/${VERSION_CODENAME}"
TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "[*] Installing Tailscale from its signed APT repository..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -d -m 0755 /usr/share/keyrings

curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$TEMP_DIR/tailscale-archive-keyring.gpg" \
    "$PACKAGE_BASE_URL.noarmor.gpg"
sudo install -m 0644 "$TEMP_DIR/tailscale-archive-keyring.gpg" "$KEYRING"

curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "$TEMP_DIR/tailscale.list" \
    "$PACKAGE_BASE_URL.tailscale-keyring.list"
sudo install -m 0644 "$TEMP_DIR/tailscale.list" "$SOURCE_LIST"

sudo apt-get update
sudo apt-get install -y tailscale
sudo systemctl enable --now tailscaled

# Required before this host can advertise default routes as an exit node.
sudo tee /etc/sysctl.d/99-tailscale.conf >/dev/null <<'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
sudo sysctl --system

echo "[OK] Tailscale is installed and tailscaled is enabled."
echo "[INFO] Authentication and exit-node advertisement are intentionally manual."
echo "[INFO] Run: sudo tailscale up"
echo "[INFO] Then run: sudo tailscale set --advertise-exit-node"
echo "[INFO] Approve this machine as an exit node in the Tailscale admin console."
