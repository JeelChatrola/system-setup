#!/usr/bin/env bash

export PLATFORM_ID PLATFORM_VERSION PLATFORM_CODENAME PLATFORM_ARCH

normalize_arch() {
    case "$1" in
        x86_64|amd64) printf '%s\n' x86_64 ;;
        aarch64|arm64) printf '%s\n' aarch64 ;;
        *) printf '%s\n' "$1" ;;
    esac
}

platform_os_release_path() {
    if [[ "${SYSTEM_SETUP_TEST_MODE:-0}" == 1 && -n "${SYSTEM_SETUP_OS_RELEASE:-}" ]]; then
        printf '%s\n' "$SYSTEM_SETUP_OS_RELEASE"
    else
        printf '%s\n' /etc/os-release
    fi
}

platform_arch() {
    if [[ "${SYSTEM_SETUP_TEST_MODE:-0}" == 1 && -n "${SYSTEM_SETUP_ARCH:-}" ]]; then
        normalize_arch "$SYSTEM_SETUP_ARCH"
    else
        normalize_arch "$(uname -m)"
    fi
}

platform_has_systemd() {
    if [[ "${SYSTEM_SETUP_TEST_MODE:-0}" == 1 && -n "${SYSTEM_SETUP_HAS_SYSTEMD:-}" ]]; then
        [[ "$SYSTEM_SETUP_HAS_SYSTEMD" == 1 ]]
    else
        command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]
    fi
}

os_release_value() {
    local file="$1" key="$2" line value
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == "$key="* ]] || continue
        value="${line#*=}"
        if [[ "$value" == \"*\" && "$value" == *\" ]]; then
            value="${value:1:${#value}-2}"
        elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
            value="${value:1:${#value}-2}"
        fi
        [[ "$value" =~ ^[A-Za-z0-9._-]+$ ]] || return 1
        printf '%s\n' "$value"
        return 0
    done <"$file"
    return 1
}

detect_platform() {
    local os_release
    os_release="$(platform_os_release_path)"
    [[ -r "$os_release" ]] || { echo "[ERROR] Cannot read $os_release" >&2; return 1; }
    PLATFORM_ID="$(os_release_value "$os_release" ID)" || { echo "[ERROR] Missing or invalid ID in $os_release" >&2; return 1; }
    PLATFORM_VERSION="$(os_release_value "$os_release" VERSION_ID)" || { echo "[ERROR] Missing or invalid VERSION_ID in $os_release" >&2; return 1; }
    PLATFORM_CODENAME="$(os_release_value "$os_release" VERSION_CODENAME)" || { echo "[ERROR] Missing or invalid VERSION_CODENAME in $os_release" >&2; return 1; }
    PLATFORM_ARCH="$(platform_arch)"
}

validate_platform() {
    local id="$1" version="$2" codename="$3" arch="$4"
    shift 4
    case "$id:$version:$codename" in
        ubuntu:24.04:noble|debian:12:bookworm) ;;
        *) echo "[ERROR] Unsupported platform: $id $version ($codename)" >&2; return 1 ;;
    esac
    case "$arch" in
        x86_64|aarch64) ;;
        *) echo "[ERROR] Unsupported architecture: $arch" >&2; return 1 ;;
    esac
    local component
    for component in "$@"; do
        if [[ "$component" == nvtop && "$arch" != x86_64 ]]; then
            echo "[ERROR] nvtop is supported only on x86_64 (detected $arch)" >&2
            return 1
        fi
    done
}

validate_target_context() {
    local uid="$1" user="$2" home="$3" home_owner="$4"
    [[ "$uid" != 0 && "$user" != root ]] || {
        echo "[ERROR] Do not run this installer as root. Run it as the intended non-root user; it will use sudo when needed." >&2
        return 1
    }
    [[ -n "$user" && -n "$home" && "$home" != /root ]] || {
        echo "[ERROR] Invalid target user or HOME" >&2
        return 1
    }
    [[ "$home_owner" == "$user" ]] || {
        echo "[ERROR] HOME ($home) is owned by $home_owner, not target user $user" >&2
        return 1
    }
}
