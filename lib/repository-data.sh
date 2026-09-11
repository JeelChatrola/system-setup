#!/usr/bin/env bash

validate_single_repository_line() {
    local repository_file="$1" expected="$2" line trimmed active_count=0
    [[ -f "$repository_file" && -r "$repository_file" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        trimmed="${line#"${line%%[![:space:]]*}"}"
        [[ -z "$trimmed" || "${trimmed:0:1}" == "#" ]] && continue
        active_count=$((active_count + 1))
        [[ "$line" == "$expected" ]] || {
            echo "[ERROR] Repository definition contains an unexpected active line" >&2
            return 1
        }
    done <"$repository_file"
    [[ "$active_count" == 1 ]] || {
        echo "[ERROR] Repository definition must contain exactly one active line" >&2
        return 1
    }
}

validate_nvidia_repository_file() {
    local repository_file="$1"
    validate_single_repository_line "$repository_file" \
        "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" || return 1
    grep -Fxq \
        "#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/experimental/deb/\$(ARCH) /" \
        "$repository_file" || {
        echo "[ERROR] Repository definition is missing the signed experimental entry" >&2
        return 1
    }
}

prepare_nvidia_repository_file() {
    local downloaded="$1" staged="$2"
    sed \
        's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' \
        "$downloaded" >"$staged"
    validate_nvidia_repository_file "$staged"
}

validate_tailscale_repository_file() {
    local repository_file="$1" platform_id="$2" codename="$3"
    validate_single_repository_line "$repository_file" \
        "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/$platform_id $codename main"
}
