#!/bin/sh
# Keep an existing multi-monitor Nitrogen layout when one has been saved.
if [ -s "${XDG_CONFIG_HOME:-$HOME/.config}/nitrogen/bg-saved.cfg" ] && command -v nitrogen >/dev/null; then
    exec nitrogen --restore
fi

for image in "$HOME/Pictures/bg.jpg" /usr/share/backgrounds/warty-final-ubuntu.png /usr/share/images/desktop-base/desktop-background; do
    if [ -f "$image" ] && [ -r "$image" ]; then
        exec feh --no-fehbg --bg-fill "$image"
    fi
done
