#!/usr/bin/env bash
# Open the preferred terminal (Ghostty, Alacritty, Kitty, then GNOME Terminal).
if command -v ghostty &>/dev/null; then
  exec ghostty "$@"
elif command -v alacritty &>/dev/null; then
  exec alacritty "$@"
elif command -v kitty &>/dev/null; then
  exec kitty "$@"
elif command -v gnome-terminal &>/dev/null; then
  exec gnome-terminal "$@"
else
  echo "No terminal found (ghostty, alacritty, kitty, gnome-terminal)" >&2
  exit 1
fi
