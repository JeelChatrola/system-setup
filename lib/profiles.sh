#!/usr/bin/env bash

COMPONENT_ORDER=(nix docker nvidia tailscale ghostty launcher i3 keybindings appearance default-shell nvtop)

is_component() {
    local candidate="$1" component
    for component in "${COMPONENT_ORDER[@]}"; do
        [[ "$candidate" == "$component" ]] && return 0
    done
    return 1
}

is_profile() {
    case "$1" in
        base|personal|workstation|server) return 0 ;;
        *) return 1 ;;
    esac
}

profile_components() {
    case "$1" in
        base) printf '%s\n' nix ;;
        personal) printf '%s\n' nix ghostty launcher appearance ;;
        workstation) printf '%s\n' nix docker ghostty launcher i3 keybindings appearance ;;
        server) printf '%s\n' nix docker ;;
        *) printf '[ERROR] Unknown profile: %s\n' "$1" >&2; return 1 ;;
    esac
}

# Usage: resolve_components PROFILE [ADD ...] [--remove REMOVE ...]
resolve_components() {
    local profile="${1:-}" mode=add item component
    local -A selected=()
    if [[ -z "$profile" ]] || ! is_profile "$profile"; then
        printf '[ERROR] Unknown profile: %s\n' "${profile:-<empty>}" >&2
        return 1
    fi
    shift

    while IFS= read -r component; do selected["$component"]=1; done < <(profile_components "$profile")
    for item in "$@"; do
        if [[ "$item" == --remove ]]; then
            mode=remove
            continue
        fi
        is_component "$item" || { printf '[ERROR] Unknown component: %s\n' "$item" >&2; return 1; }
        if [[ "$mode" == add ]]; then selected["$item"]=1; else unset 'selected[$item]'; fi
    done

    local result=()
    for component in "${COMPONENT_ORDER[@]}"; do
        [[ -v "selected[$component]" ]] && result+=("$component")
    done
    printf '%s\n' "${result[*]}"
}

validate_component_dependencies() {
    # Selection validation is static. Existing Docker is checked only at apply time.
    return 0
}

validate_runtime_dependencies() {
    local mode="$1" component has_docker=false has_nvidia=false has_launcher=false has_i3=false
    shift
    [[ "$mode" == apply ]] || return 0
    for component in "$@"; do
        [[ "$component" == docker ]] && has_docker=true
        [[ "$component" == nvidia ]] && has_nvidia=true
        [[ "$component" == launcher ]] && has_launcher=true
        [[ "$component" == i3 ]] && has_i3=true
    done
    if $has_nvidia && ! $has_docker; then
        sudo docker info >/dev/null 2>&1 || {
            echo "[ERROR] nvidia requires a working existing Docker daemon or the docker component" >&2
            return 1
        }
    fi
    if $has_i3 && ! $has_launcher && ! command -v rofi >/dev/null 2>&1; then
        echo "[ERROR] standalone i3 requires existing Rofi; select the launcher component first" >&2
        return 1
    fi
}
