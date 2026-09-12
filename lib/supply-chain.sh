#!/usr/bin/env bash

normalize_fingerprint() {
    local fingerprint="${1//[[:space:]]/}"
    fingerprint="${fingerprint^^}"
    [[ "$fingerprint" =~ ^[0-9A-F]{40}$ ]] || return 1
    printf '%s\n' "$fingerprint"
}

verify_openpgp_fingerprint() {
    local key_file="$1" expected="$2" listing record fingerprint="" pub_count=0
    expected="$(normalize_fingerprint "$expected")" || {
        echo "[ERROR] Invalid expected OpenPGP fingerprint" >&2
        return 1
    }
    listing="$(gpg --batch --show-keys --with-colons "$key_file")" || {
        echo "[ERROR] Could not inspect downloaded OpenPGP key" >&2
        return 1
    }

    while IFS=: read -r record _ _ _ _ _ _ _ _ value _; do
        if [[ "$record" == pub ]]; then
            pub_count=$((pub_count + 1))
        elif [[ "$record" == fpr && -z "$fingerprint" ]]; then
            fingerprint="$(normalize_fingerprint "$value")" || return 1
        fi
    done <<<"$listing"

    if [[ "$pub_count" != 1 || "$fingerprint" != "$expected" ]]; then
        echo "[ERROR] Downloaded OpenPGP key fingerprint mismatch (expected $expected, got ${fingerprint:-none})" >&2
        return 1
    fi
}

download_verified_file() {
    local url="$1" expected="$2" destination="$3" temporary actual
    [[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || {
        echo "[ERROR] Invalid expected SHA-256 checksum" >&2
        return 1
    }
    temporary="$(mktemp "$(dirname "$destination")/.download.XXXXXX")" || return 1
    if ! curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error --output "$temporary" "$url"; then
        rm -f "$temporary"
        return 1
    fi
    actual="$(sha256sum "$temporary")" || {
        rm -f "$temporary"
        return 1
    }
    actual="${actual%% *}"
    if [[ "${actual,,}" != "${expected,,}" ]]; then
        echo "[ERROR] SHA-256 mismatch for $url (expected ${expected,,}, got ${actual,,})" >&2
        rm -f "$temporary"
        return 1
    fi
    mv -f "$temporary" "$destination"
}
