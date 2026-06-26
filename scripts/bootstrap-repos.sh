#!/bin/bash
# Clone or update nix-config and private ai-stack.

set -euo pipefail

NIX_CONFIG_REPO="${NIX_CONFIG_REPO:-git@github.com:JeelChatrola/nix-config.git}"
AI_STACK_REPO="${AI_STACK_REPO:-git@github.com:JeelChatrola/ai-stack.git}"
NIX_CONFIG_DIR="${NIX_CONFIG_DIR:-$HOME/nix-config}"
AI_STACK_DIR="${AI_STACK_DIR:-$HOME/ai-stack}"

clone_or_pull() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    echo "[*] Updating $dest"
    git -C "$dest" pull --ff-only
  else
    echo "[*] Cloning $url -> $dest"
    git clone "$url" "$dest"
  fi
}

echo "[*] Bootstrapping config repos..."
clone_or_pull "$NIX_CONFIG_REPO" "$NIX_CONFIG_DIR"
clone_or_pull "$AI_STACK_REPO" "$AI_STACK_DIR"

if [[ -f "$AI_STACK_DIR/.gitmodules" ]]; then
  echo "[*] Initializing ai-stack submodules (optional robotics skills)..."
  git -C "$AI_STACK_DIR" submodule update --init --recursive || true
fi

echo ""
echo "[OK] Repos ready:"
echo "  nix-config: $NIX_CONFIG_DIR"
echo "  ai-stack:   $AI_STACK_DIR"
echo ""
echo "Next:"
echo "  cd $NIX_CONFIG_DIR && ./deploy.sh"
echo "  cd $NIX_CONFIG_DIR && ./deploy.sh --ai"
