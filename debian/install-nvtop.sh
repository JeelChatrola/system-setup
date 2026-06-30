#!/bin/bash
# Install nvtop via upstream AppImage (system GPU drivers; not Nix).
# Ubuntu apt ships 3.0.2, which crashes on AMD iGPU + NVIDIA hybrid setups.

set -euo pipefail

NVTOP_VERSION="${NVTOP_VERSION:-3.3.2}"
INSTALL_DIR="${HOME}/.local/bin"
APPIMAGE="${INSTALL_DIR}/nvtop-${NVTOP_VERSION}-x86_64.AppImage"
LINK="${INSTALL_DIR}/nvtop"
URL="https://github.com/Syllo/nvtop/releases/download/${NVTOP_VERSION}/nvtop-${NVTOP_VERSION}-x86_64.AppImage"

echo "[*] Installing nvtop ${NVTOP_VERSION} (AppImage)..."

mkdir -p "${INSTALL_DIR}"

if [[ -x "${APPIMAGE}" ]]; then
  echo "[OK] nvtop AppImage already present at ${APPIMAGE}"
else
  echo "[*] Downloading ${URL}"
  curl -fsSL -o "${APPIMAGE}.partial" "${URL}"
  chmod +x "${APPIMAGE}.partial"
  mv "${APPIMAGE}.partial" "${APPIMAGE}"
fi

ln -sf "${APPIMAGE}" "${LINK}"

if ! command -v nvtop &>/dev/null; then
  echo "[WARN] nvtop is not on PATH. Ensure ~/.local/bin is in PATH."
fi

echo "[OK] nvtop installed"
"${LINK}" --version

if dpkg -s nvtop &>/dev/null; then
  echo "[INFO] apt nvtop is still installed. Remove it to avoid confusion:"
  echo "       sudo apt remove nvtop"
fi
