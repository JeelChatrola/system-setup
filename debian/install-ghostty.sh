#!/bin/bash
# Install Ghostty terminal on Debian-based systems.

set -e

echo "[*] Installing Ghostty..."

if command -v ghostty &>/dev/null; then
  echo "[OK] Ghostty is already installed"
  ghostty --version
  exit 0
fi

if command -v nix &>/dev/null; then
  echo "[*] Installing via nix profile..."
  nix profile install nixpkgs#ghostty
  if command -v ghostty &>/dev/null; then
    echo "[OK] Ghostty installed via Nix"
    ghostty --version
    exit 0
  fi
fi

echo "[WARN] Ghostty not in apt on all releases. Install manually:"
echo "  nix profile install nixpkgs#ghostty"
echo "  or see https://ghostty.org/docs/install"
exit 1
