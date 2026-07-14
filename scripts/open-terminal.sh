#!/usr/bin/env bash
# Open the preferred terminal (Ghostty, then GNOME Terminal).
if command -v ghostty &>/dev/null; then
  exec ghostty "$@"
elif command -v gnome-terminal &>/dev/null; then
  exec gnome-terminal "$@"
else
  echo "No terminal found (ghostty, gnome-terminal)" >&2
  exit 1
fi
