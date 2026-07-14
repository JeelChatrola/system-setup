#!/bin/bash
# Install nvtop via upstream AppImage (system GPU drivers; not Nix).
# Ubuntu apt ships 3.0.2, which crashes on AMD iGPU + NVIDIA hybrid setups.

set -euo pipefail

NVTOP_VERSION="3.3.2"
NVTOP_SHA256="a0b06f86cda836fd59aa526baf1f263e1c2d74d58d52e8cdb1619d5dcfde2387"
INSTALL_DIR="${HOME}/.local/bin"
APPIMAGE="${INSTALL_DIR}/nvtop-${NVTOP_VERSION}-x86_64.AppImage"
LINK="${INSTALL_DIR}/nvtop"
URL="https://github.com/Syllo/nvtop/releases/download/${NVTOP_VERSION}/nvtop-${NVTOP_VERSION}-x86_64.AppImage"
PARTIAL_APPIMAGE="${APPIMAGE}.partial"

cleanup() {
  rm -f "${PARTIAL_APPIMAGE}"
}
trap cleanup EXIT

verify_appimage() {
  local path="$1"
  local actual_sha256
  actual_sha256="$(sha256sum "$path" | awk '{print $1}')"

  if [[ "$actual_sha256" != "$NVTOP_SHA256" ]]; then
    echo "[ERROR] Checksum mismatch for $path" >&2
    echo "[ERROR] Expected: $NVTOP_SHA256" >&2
    echo "[ERROR] Actual:   $actual_sha256" >&2
    return 1
  fi
}

echo "[*] Installing nvtop ${NVTOP_VERSION} (AppImage)..."

mkdir -p "${INSTALL_DIR}"

if [[ -f "${APPIMAGE}" ]]; then
  if verify_appimage "${APPIMAGE}"; then
    echo "[OK] Verified existing nvtop AppImage at ${APPIMAGE}"
  else
    echo "[WARN] Removing untrusted nvtop AppImage and downloading a verified copy."
    rm -f "${APPIMAGE}"
  fi
fi

if [[ ! -f "${APPIMAGE}" ]]; then
  echo "[*] Downloading ${URL}"
  curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
    --output "${PARTIAL_APPIMAGE}" "${URL}"
  verify_appimage "${PARTIAL_APPIMAGE}"
  mv "${PARTIAL_APPIMAGE}" "${APPIMAGE}"
fi

chmod 0755 "${APPIMAGE}"
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
