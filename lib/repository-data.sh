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
    validate_single_repository_line "$1" "deb https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /"
}

validate_tailscale_repository_file() {
    local repository_file="$1" platform_id="$2" codename="$3"
    validate_single_repository_line "$repository_file" \
        "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/$platform_id $codename main"
}
