#!/usr/bin/env bash

set -euo pipefail

zsh_path="$HOME/.nix-profile/bin/zsh"
if [[ ! -x "$zsh_path" ]]; then
    echo "[ERROR] Missing $zsh_path. Deploy nix-config first so it provides zsh at that path, then rerun the default-shell component." >&2
    exit 1
fi

if ! username="$(id -un)" || [[ -z "$username" ]] \
    || ! current_shell="$(getent passwd "$username" | cut -s -d: -f7)" || [[ -z "$current_shell" ]]; then
    echo "[ERROR] Unable to look up the current user's passwd shell; default shell unchanged. Check the passwd/NSS configuration, then rerun." >&2
    exit 1
fi

if ! grep -Fxq "$zsh_path" /etc/shells; then
    shells_tmp="$(mktemp)"
    trap 'rm -f "$shells_tmp"' EXIT
    cat /etc/shells >"$shells_tmp"
    printf '%s\n' "$zsh_path" >>"$shells_tmp"
    sudo install -m 0644 "$shells_tmp" /etc/shells
fi

if [[ "$current_shell" == "$zsh_path" ]]; then
    echo "[OK] Default shell is already $zsh_path"
    exit 0
fi

if [[ "${SYSTEM_SETUP_YES:-0}" != 1 ]]; then
    [[ -t 0 ]] || { echo "[ERROR] Changing the default shell requires confirmation; rerun with --yes or from an interactive terminal" >&2; exit 1; }
    read -r -p "Change the default shell to Nix zsh ($zsh_path)? [y/N]: " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "[INFO] Default shell unchanged"; exit 0; }
fi

chsh -s "$zsh_path"
if ! current_shell="$(getent passwd "$username" | cut -s -d: -f7)" || [[ "$current_shell" != "$zsh_path" ]]; then
    echo "[ERROR] Could not verify the default shell change from passwd" >&2
    exit 1
fi
echo "[OK] Default shell changed to $zsh_path; it will be used at next login"
