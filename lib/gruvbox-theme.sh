#!/usr/bin/env bash

GRUVBOX_OWNER_MARKER_CONTENT='system-setup:gruvbox-bundle:v1'

validate_gruvbox_source_layout() {
    local archive_root="$1" themes_dir="$1/themes" required
    [[ -d "$themes_dir" \
        && -f "$themes_dir/install.sh" \
        && -r "$themes_dir/install.sh" \
        && -x "$themes_dir/install.sh" \
        && -f "$themes_dir/gtkrc.sh" \
        && -r "$themes_dir/gtkrc.sh" ]] || {
        echo "[ERROR] Verified Gruvbox archive does not contain the expected executable theme sources" >&2
        return 1
    }
    for required in \
        src/assets/cinnamon \
        src/assets/gnome-shell \
        src/assets/gtk \
        src/assets/gtk-2.0 \
        src/assets/metacity-1 \
        src/assets/xfwm4 \
        src/main/cinnamon \
        src/main/gnome-shell \
        src/main/gtk-2.0 \
        src/main/gtk-3.0 \
        src/main/gtk-4.0 \
        src/main/metacity-1 \
        src/main/plank \
        src/main/xfwm4 \
        src/sass/gnome-shell; do
        [[ -d "$themes_dir/$required" ]] || {
            echo "[ERROR] Verified Gruvbox archive is missing source directory: themes/$required" >&2
            return 1
        }
    done
    for required in \
        src/main/gnome-shell/gnome-shell-Dark.scss \
        src/main/gtk-3.0/gtk-Dark.scss \
        src/main/gtk-4.0/gtk-Dark.scss \
        src/sass/_tweaks.scss \
        src/sass/gnome-shell/_common.scss; do
        [[ -r "$themes_dir/$required" ]] || {
            echo "[ERROR] Verified Gruvbox archive is missing source file: themes/$required" >&2
            return 1
        }
    done
}

build_gruvbox_theme() {
    local archive_root="$1" destination="$2"
    validate_gruvbox_source_layout "$archive_root" || return 1
    command -v sassc >/dev/null 2>&1 || {
        echo "[ERROR] sassc must be installed before building the Gruvbox theme" >&2
        return 1
    }
    [[ -d "$destination" ]] || {
        echo "[ERROR] Gruvbox staging destination does not exist: $destination" >&2
        return 1
    }
    "$archive_root/themes/install.sh" \
        --dest "$destination" \
        --theme default \
        --color dark \
        --size standard </dev/null
}

validate_gruvbox_theme() {
    local theme_dir="$1" required asset_dir
    [[ -d "$theme_dir" ]] || return 1
    for required in \
        index.theme \
        gtk-2.0/gtkrc \
        gtk-3.0/gtk.css \
        gtk-3.0/gtk-dark.css \
        gtk-4.0/gtk.css \
        gtk-4.0/gtk-dark.css \
        gnome-shell/gnome-shell.css \
        cinnamon/cinnamon.css \
        metacity-1/metacity-theme-3.xml \
        xfwm4/themerc; do
        [[ -s "$theme_dir/$required" ]] || {
            echo "[ERROR] Generated Gruvbox theme is missing required file: $required" >&2
            return 1
        }
    done
    for asset_dir in \
        gtk-2.0/assets \
        gtk-3.0/assets \
        gtk-4.0/assets \
        gnome-shell/assets \
        cinnamon/assets \
        metacity-1/assets \
        plank; do
        if [[ ! -d "$theme_dir/$asset_dir" ]] || ! compgen -G "$theme_dir/$asset_dir/*" >/dev/null; then
            echo "[ERROR] Generated Gruvbox theme has an empty or missing asset directory: $asset_dir" >&2
            return 1
        fi
    done
    compgen -G "$theme_dir/xfwm4/*.png" >/dev/null || {
        echo "[ERROR] Generated Gruvbox theme has no XFWM assets" >&2
        return 1
    }
}

validate_gruvbox_bundle() {
    local bundle_dir="$1" scale
    validate_gruvbox_theme "$bundle_dir/Gruvbox-Dark" || return 1
    for scale in hdpi xhdpi; do
        if [[ ! -s "$bundle_dir/Gruvbox-Dark-$scale/xfwm4/themerc" ]] \
            || ! compgen -G "$bundle_dir/Gruvbox-Dark-$scale/xfwm4/*.png" >/dev/null; then
            echo "[ERROR] Generated Gruvbox-$scale sibling is incomplete" >&2
            return 1
        fi
    done
}

write_gruvbox_ownership_marker() {
    local bundle_dir="$1" bundle_name marker_tmp
    bundle_name="$(basename "$bundle_dir")"
    [[ -d "$bundle_dir" && ! -L "$bundle_dir" \
        && "$bundle_name" =~ ^\.system-setup-gruvbox-[0-9a-f]{40}(\.[A-Za-z0-9][A-Za-z0-9._-]*)?$ ]] || return 1
    marker_tmp="$(mktemp "$bundle_dir/.owner-marker.XXXXXX")" || return 1
    printf '%s\n' "$GRUVBOX_OWNER_MARKER_CONTENT" >"$marker_tmp"
    chmod 0644 "$marker_tmp"
    mv -Tf "$marker_tmp" "$bundle_dir/.system-setup-owner"
}

is_installer_owned_gruvbox_target() {
    local themes_dir="$1" target="$2" bundle_name bundle_dir marker theme_dir marker_content
    [[ "$target" =~ ^(\.system-setup-gruvbox-[0-9a-f]{40}(\.[A-Za-z0-9][A-Za-z0-9._-]*)?)/Gruvbox-Dark$ ]] || return 1
    bundle_name="${BASH_REMATCH[1]}"
    bundle_dir="$themes_dir/$bundle_name"
    marker="$bundle_dir/.system-setup-owner"
    theme_dir="$bundle_dir/Gruvbox-Dark"
    [[ -d "$bundle_dir" && ! -L "$bundle_dir" \
        && -f "$marker" && ! -L "$marker" \
        && -d "$theme_dir" && ! -L "$theme_dir" ]] || return 1
    marker_content="$(<"$marker")"
    [[ "$marker_content" == "$GRUVBOX_OWNER_MARKER_CONTENT" ]]
}

refuse_unmanaged_gruvbox_stable() {
    local themes_dir="$1" stable="$1/Gruvbox-Dark" target
    [[ -e "$stable" || -L "$stable" ]] || return 0
    if [[ -L "$stable" ]]; then
        target="$(readlink -- "$stable")" || target=""
        is_installer_owned_gruvbox_target "$themes_dir" "$target" && return 0
    fi
    echo "[ERROR] Refusing to replace unmanaged theme path: $stable" >&2
    echo "[ERROR] Move or remove it manually, then rerun the appearance component. The path was left unchanged." >&2
    return 1
}

publish_gruvbox_stable_link() {
    local themes_dir="$1" bundle_dir="$2" bundle_name target stable link_stage
    bundle_name="$(basename "$bundle_dir")"
    [[ "$(dirname "$bundle_dir")" == "$themes_dir" ]] || return 1
    target="$bundle_name/Gruvbox-Dark"
    is_installer_owned_gruvbox_target "$themes_dir" "$target" || return 1
    validate_gruvbox_bundle "$bundle_dir" || return 1
    refuse_unmanaged_gruvbox_stable "$themes_dir" || return 1

    stable="$themes_dir/Gruvbox-Dark"
    link_stage="$(mktemp -d "$themes_dir/.gruvbox-link.XXXXXX")" || return 1
    if ! ln -s "$target" "$link_stage/link" || ! mv -Tf "$link_stage/link" "$stable"; then
        rm -f "$link_stage/link"
        rmdir "$link_stage"
        return 1
    fi
    rmdir "$link_stage"
}
