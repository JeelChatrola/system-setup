#!/usr/bin/env bash
set -euo pipefail

# Prefer a system package. Keep the fallback outside the Home Manager profile.
state="${XDG_STATE_HOME:-$HOME/.local/state}/system-setup"
binary="$(command -v albert || true)"
link="$HOME/.local/bin/albert"
screenshot=()
if [[ -z "$binary" || "$(readlink "$link" || true)" == "$state/albert-package/bin/albert" && "$binary" == "$link" ]]; then
    export PATH="$PATH:/nix/var/nix/profiles/default/bin"
    if ! command -v nix >/dev/null; then
        echo "Install the nix component or a native Albert 35 package first." >&2
        exit 1
    fi
    mkdir -p "$state"
    revision=79b6d20e55596f80baa35cda2a334da8a1fbf1ea
    old_package="$(readlink "$state/albert-package" || true)"
    NIXPKGS_ALLOW_UNFREE=1 nix --extra-experimental-features "nix-command flakes" build \
        --impure --out-link "$state/albert-package" "github:NixOS/nixpkgs/$revision#albert"
    binary="$state/albert-package/bin/albert"
    if ! command -v xfce4-screenshooter >/dev/null && ! command -v gnome-screenshot >/dev/null && ! command -v flameshot >/dev/null; then
        old_tool="$(readlink "$state/albert-screenshooter" || true)"
        nix --extra-experimental-features "nix-command flakes" build --out-link "$state/albert-screenshooter" \
            "github:NixOS/nixpkgs/$revision#xfce4-screenshooter"
        screenshot=("$state/albert-screenshooter/bin/xfce4-screenshooter")
        if [[ "$(readlink "$state/albert-screenshooter")" != "$old_tool" ]]; then
            echo "Updated screenshot tool"
        fi
    fi
    mkdir -p "$(dirname "$link")"
    if [[ ! -e "$link" && ! -L "$link" ]]; then
        ln -s "$binary" "$link"
        echo "Updated $link"
    fi
    if [[ "$(readlink "$state/albert-package")" != "$old_package" ]]; then
        echo "Updated Albert package"
    fi
fi
exec /usr/bin/python3 "$(dirname "${BASH_SOURCE[0]}")/configure.py" "$binary" "${screenshot[@]}"
