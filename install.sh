#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/profiles.sh
source "$SCRIPT_DIR/lib/profiles.sh"
# shellcheck source=lib/platform.sh
source "$SCRIPT_DIR/lib/platform.sh"

usage() {
    cat <<'EOF'
Usage:
  ./install.sh --profile PROFILE [--add COMPONENT]... [--remove COMPONENT]... [--plan] [--yes] [--add-docker-group]
  ./install.sh --component COMPONENT [--plan] [--yes] [--add-docker-group]
EOF
}

die() { printf '[ERROR] %s\n' "$1" >&2; exit 1; }

profile=""
single_component=""
plan=false
assume_yes=false
add_docker_group=false
adds=()
removes=()

while (($#)); do
    case "$1" in
        --profile|--component|--add|--remove)
            option="$1"
            (($# >= 2)) || die "$option requires a value"
            value="$2"
            [[ "$value" != --* ]] || die "$option requires a value"
            case "$option" in
                --profile) [[ -z "$profile" ]] || die "--profile may be specified only once"; profile="$value" ;;
                --component) [[ -z "$single_component" ]] || die "--component may be specified only once"; single_component="$value" ;;
                --add) adds+=("$value") ;;
                --remove) removes+=("$value") ;;
            esac
            shift 2
            ;;
        --plan) plan=true; shift ;;
        --yes) assume_yes=true; shift ;;
        --add-docker-group) add_docker_group=true; shift ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown argument: $1" ;;
    esac
done

[[ -n "$profile" || -n "$single_component" ]] || die "exactly one --profile or --component is required"
[[ -z "$profile" || -z "$single_component" ]] || die "--profile and --component cannot be combined"

if [[ -n "$single_component" ]]; then
    ((${#adds[@]} == 0 && ${#removes[@]} == 0)) || die "--add/--remove can only be used with --profile"
    is_component "$single_component" || die "Unknown component: $single_component"
    components=("$single_component")
    selection_label="Component: $single_component"
else
    is_profile "$profile" || die "Unknown profile: $profile"
    for component in "${adds[@]}" "${removes[@]}"; do
        [[ -z "$component" ]] || is_component "$component" || die "Unknown component: $component"
    done
    resolver_args=("$profile" "${adds[@]}")
    ((${#removes[@]} == 0)) || resolver_args+=(--remove "${removes[@]}")
    read -r -a components <<<"$(resolve_components "${resolver_args[@]}")"
    selection_label="Profile: $profile"
fi

((${#components[@]} > 0)) || die "selection resolves to no components"
validate_component_dependencies "${components[@]}"
detect_platform
validate_platform "$PLATFORM_ID" "$PLATFORM_VERSION" "$PLATFORM_CODENAME" "$PLATFORM_ARCH" "${components[@]}"

printf 'OS: %s %s (%s)\n' "$PLATFORM_ID" "$PLATFORM_VERSION" "$PLATFORM_ARCH"
printf '%s\n' "$selection_label"
printf 'Components: %s\n' "${components[*]}"
for component in "${components[@]}"; do
    case "$component" in
        nvidia|i3|keybindings) echo "runtime dependency checks deferred until apply: $component" ;;
    esac
done

$plan && exit 0

target_user="$(id -un)"
home_owner="$(stat -c %U "$HOME" 2>/dev/null)" || die "HOME must be an existing directory"
validate_target_context "$EUID" "$target_user" "$HOME" "$home_owner"
command -v apt-get >/dev/null 2>&1 || die "apt-get is required"
command -v sudo >/dev/null 2>&1 || die "sudo is required"
[[ -d "$HOME" && -w "$HOME" ]] || die "HOME must be an existing writable directory"

[[ "$(uname -s)" == Linux ]] || die "components require Linux"
validate_runtime_dependencies apply "${components[@]}"

terminal_selected=false
for component in "${components[@]}"; do [[ "$component" == ghostty ]] && terminal_selected=true; done
for component in "${components[@]}"; do
    if [[ "$component" == i3 || "$component" == keybindings ]]; then
        if ! $terminal_selected && ! "$SCRIPT_DIR/scripts/open-terminal.sh" --check >/dev/null 2>&1; then
            die "$component requires a usable terminal or the ghostty component"
        fi
    fi
done

declare -A COMPONENT_SCRIPTS=(
    [nix]="debian/install-nix.sh"
    [docker]="debian/install-docker.sh"
    [nvidia]="debian/install-nvidia-toolkit.sh"
    [tailscale]="debian/install-tailscale.sh"
    [ghostty]="debian/install-ghostty.sh"
    [launcher]="debian/install-launcher.sh"
    [i3]="debian/install-i3.sh"
    [keybindings]="debian/setup-keybindings.sh"
    [appearance]="debian/setup-appearance.sh"
    [flatpak]="debian/install-flatpak.sh"
    [default-shell]="debian/setup-default-shell.sh"
    [nvtop]="debian/install-nvtop.sh"
)

export SYSTEM_SETUP_YES=0 SYSTEM_SETUP_ADD_DOCKER_GROUP=0 SYSTEM_SETUP_TARGET_USER="$target_user"
$assume_yes && export SYSTEM_SETUP_YES=1
$add_docker_group && export SYSTEM_SETUP_ADD_DOCKER_GROUP=1

for component in "${components[@]}"; do
    script="$SCRIPT_DIR/${COMPONENT_SCRIPTS[$component]}"
    [[ -r "$script" ]] || die "Missing component script: $script"
done

for component in "${components[@]}"; do
    printf '\n[*] Applying component: %s\n' "$component"
    bash "$SCRIPT_DIR/${COMPONENT_SCRIPTS[$component]}"
done

echo "[OK] System setup complete"
