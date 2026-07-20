#!/usr/bin/env bash

ensure_nix_features() {
    local config_file="$1" directory temporary line token feature_values wrote_features=false
    local -a lines=() features=()
    local -A seen=()
    directory="$(dirname "$config_file")"
    mkdir -p "$directory"

    if [[ -f "$config_file" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do lines+=("$line"); done <"$config_file"
    fi
    for line in "${lines[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*experimental-features[[:space:]]*=(.*)$ ]]; then
            feature_values="${BASH_REMATCH[1]%%#*}"
            for token in $feature_values; do
                [[ -v "seen[$token]" ]] || { seen["$token"]=1; features+=("$token"); }
            done
        fi
    done
    for token in nix-command flakes; do
        [[ -v "seen[$token]" ]] || { seen["$token"]=1; features+=("$token"); }
    done

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
