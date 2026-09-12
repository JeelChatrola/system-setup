#!/usr/bin/env bash

ensure_nix_features() {
    local config_file="$1" directory temporary line token feature_values wrote_features=false
    local -a lines=() features=() tokens=()
    local -A seen=()
    if [[ -f "$config_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do lines+=("$line"); done <"$config_file"
    fi
    for line in "${lines[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*(extra-)?experimental-features[[:space:]]*=(.*)$ ]]; then
            feature_values="${BASH_REMATCH[2]%%#*}"
            if [[ -L "$config_file" ]]; then
                # Base assignments replace earlier values; extra- assignments append.
                if [[ -z "${BASH_REMATCH[1]}" ]]; then seen=(); features=(); fi
            elif [[ -n "${BASH_REMATCH[1]}" ]]; then
                continue
            fi
            read -r -a tokens <<<"$feature_values"
            for token in "${tokens[@]}"; do
                [[ -v "seen[$token]" ]] || { seen["$token"]=1; features+=("$token"); }
            done
        fi
    done
    if [[ -L "$config_file" ]]; then
        if [[ -v 'seen[nix-command]' && -v 'seen[flakes]' ]]; then return 0; fi
        printf '[ERROR] %s is a symlink. Enable nix-command and flakes in the owning configuration (for example, nix-config/Home Manager), redeploy it, then rerun. The symlink and its target were not changed.\n' "$config_file" >&2
        return 1
    fi
    for token in nix-command flakes; do
        [[ -v "seen[$token]" ]] || { seen["$token"]=1; features+=("$token"); }
    done

    directory="$(dirname "$config_file")"
    mkdir -p "$directory"
    temporary="$(mktemp "$directory/.nix.conf.XXXXXX")"
    for line in "${lines[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*experimental-features[[:space:]]*= ]]; then
            if ! $wrote_features; then
                printf 'experimental-features = %s\n' "${features[*]}" >>"$temporary"
                wrote_features=true
            fi
        else
            printf '%s\n' "$line" >>"$temporary"
        fi
    done
    if ! $wrote_features; then printf 'experimental-features = %s\n' "${features[*]}" >>"$temporary"; fi
    chmod 0644 "$temporary"
    if [[ -f "$config_file" ]] && cmp -s "$temporary" "$config_file"; then
        rm -f "$temporary"
    else
        mv "$temporary" "$config_file"
    fi
}
