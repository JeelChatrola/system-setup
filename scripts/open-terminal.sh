#!/usr/bin/env bash

set -euo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"

usable_terminal() {
    local candidate="$1" path
    [[ -n "$candidate" ]] || return 1
    path="$(command -v "$candidate" 2>/dev/null)" || return 1
    [[ "$(readlink -f "$path")" != "$SELF" ]]
}

terminal=""
if usable_terminal "${TERMINAL:-}"; then
    terminal="$TERMINAL"
else
    for candidate in ghostty x-terminal-emulator i3-sensible-terminal gnome-terminal; do
        if usable_terminal "$candidate"; then
            terminal="$candidate"
            break
        fi
    done
fi

if [[ -z "$terminal" ]]; then
    echo "[ERROR] No usable terminal found (TERMINAL, ghostty, x-terminal-emulator, i3-sensible-terminal, gnome-terminal)" >&2
    exit 1
fi

[[ "${1:-}" == --check ]] && exit 0
exec "$terminal" "$@"
