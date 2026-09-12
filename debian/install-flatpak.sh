#!/bin/bash
# Install and converge Flatpak + Flathub + managed GUI apps (system scope).
# System-setup owns the Flatpak runtime and system-wide GUI apps;
# Nix/Home Manager owns CLI tools and dotfiles, not these apps.
#
# Usage:
#   debian/install-flatpak.sh [--plan] [--apps FILE] [--system|--user]
#
# --plan prints what would be installed without writes, sudo, or network.
# Default scope is --system (matches current workstation: all 4 observed
# apps are system installs). Managed list defaults to configs/flatpak-apps.txt.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
APPS_FILE="${REPO_ROOT}/configs/flatpak-apps.txt"
SCOPE="--system"
PLAN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan) PLAN=true; shift ;;
    --apps) APPS_FILE="$2"; shift 2 ;;
    --system|--user) SCOPE="$1"; shift ;;
    -h|--help)
      echo "Usage: $(basename "$0") [--plan] [--apps FILE] [--system|--user]"
      exit 0
      ;;
    *) echo "[ERROR] Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ ! -f "${APPS_FILE}" ]]; then
  echo "[ERROR] Apps list not found: ${APPS_FILE}" >&2
  exit 1
fi

mapfile -t APPS < <(grep -vE '^\s*(#|$)' "${APPS_FILE}" | awk '{print $1}')

if [[ "${PLAN}" == true ]]; then
  echo "[PLAN] scope: ${SCOPE#--} (no writes, no sudo, no network)"
  echo "[PLAN] ensure: flatpak package installed, flathub remote present"
  for app in "${APPS[@]}"; do
    echo "[PLAN] ensure installed: ${app}"
  done
  echo "[PLAN] Cursor/VSCode stay manual (not on Flathub)."
  exit 0
fi

if ! command -v apt &>/dev/null; then
  echo "[ERROR] This script is for Debian-based systems only" >&2
  exit 1
fi

if ! command -v flatpak &>/dev/null; then
  echo "[*] Installing flatpak..."
  sudo apt update
  sudo apt install -y flatpak
fi

if ! flatpak remotes "${SCOPE}" 2>/dev/null | grep -q '^flathub'; then
  echo "[*] Adding Flathub remote (${SCOPE#--})..."
  sudo flatpak remote-add --if-not-exists "${SCOPE}" flathub https://dl.flathub.org/repo/flathub.flatpakrepo
else
  echo "[OK] Flathub remote present (${SCOPE#--})"
fi

failed=0
for app in "${APPS[@]}"; do
  if flatpak list "${SCOPE}" --app --columns=application 2>/dev/null | grep -qx "${app}"; then
    echo "[OK] Already installed: ${app}"
  else
    echo "[*] Installing ${app} (${SCOPE#--})..."
    if ! sudo flatpak install -y "${SCOPE}" flathub "${app}"; then
      echo "[ERROR] Failed to install ${app}" >&2
      failed=$((failed + 1))
    fi
  fi
done

if [[ "${failed}" -gt 0 ]]; then
  echo "[ERROR] ${failed} app(s) failed to install" >&2
  exit 1
fi

echo "[OK] Flatpak converged (${SCOPE#--}): ${#APPS[@]} managed app(s)"
flatpak list "${SCOPE}" --app --columns=application,name,installation
