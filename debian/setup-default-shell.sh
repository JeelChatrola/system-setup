#!/usr/bin/env bash

set -euo pipefail

zsh_path="$HOME/.nix-profile/bin/zsh"
if [[ ! -x "$zsh_path" ]]; then
    echo "[ERROR] Missing $zsh_path. Deploy nix-config first so it provides zsh at that path, then rerun the default-shell component." >&2
    exit 1
fi

if ! grep -Fxq "$zsh_path" /etc/shells; then
    shells_tmp="$(mktemp)"
    trap 'rm -f "$shells_tmp"' EXIT
    cat /etc/shells >"$shells_tmp"
    printf '%s\n' "$zsh_path" >>"$shells_tmp"
    sudo install -m 0644 "$shells_tmp" /etc/shells
fi

if [[ "${SHELL:-}" == "$zsh_path" ]] || [[ "$(getent passwd "$(id -un)" | cut -d: -f7)" == "$zsh_path" ]]; then
    echo "[OK] Default shell is already $zsh_path"
    exit 0
fi

if [[ "${SYSTEM_SETUP_YES:-0}" != 1 ]]; then
    [[ -t 0 ]] || { echo "[ERROR] Changing the default shell requires confirmation; rerun with --yes or from an interactive terminal" >&2; exit 1; }
    read -r -p "Change the default shell to Nix zsh ($zsh_path)? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "[INFO] Default shell unchanged"; exit 0; }
fi

chsh -s "$zsh_path"
[[ "$(getent passwd "$(id -un)" | cut -d: -f7)" == "$zsh_path" ]] || {
    echo "[ERROR] Default shell change did not take effect" >&2
    exit 1
}
echo "[OK] Default shell changed to $zsh_path; it will be used at next login"
