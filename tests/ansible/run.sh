#!/usr/bin/env bash
set -euo pipefail

# Run from any directory. Ansible and its pinned collections must be installed.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp="$(mktemp -d)"
container=""
cleanup() {
    if [[ -n "$container" ]]; then docker rm -f "$container" >/dev/null; fi
    rm -rf "$tmp"
}
trap cleanup EXIT

targets=("${@}")
if ((${#targets[@]} == 0)); then targets=(ubuntu:24.04 debian:12 debian:13 archlinux:base); fi
for image in "${targets[@]}"; do
    label="${image//[:\/]/-}"
    tag="system-setup-test:$label"
    # Rolling Arch mirrors remove old package versions. Always build a fresh,
    # fully upgraded fixture instead of reusing cached package databases.
    docker build --pull --no-cache --build-arg "BASE_IMAGE=$image" -t "$tag" -f "$ROOT/tests/ansible/Dockerfile" "$ROOT/tests/ansible"
    container="$(docker run -d --rm "$tag")"
    printf '[setup]\ntesthost ansible_host=%s ansible_connection=community.docker.docker ansible_python_interpreter=/usr/bin/python3\n' "$container" > "$tmp/inventory"
    options=(-i "$tmp/inventory" -e setup_user=tester -e '{"setup_manage_services":false}')
    components='{"setup_components":["docker","nvidia","tailscale","launcher"]}'

    ansible-playbook "${options[@]}" -e setup_profile=workstation --tags plan "$ROOT/ansible/site.yml"

    ansible-playbook "${options[@]}" "$ROOT/tests/ansible/fixtures.yml"
    ansible-playbook "${options[@]}" -e "$components" "$ROOT/ansible/site.yml"
    ansible-playbook "${options[@]}" "$ROOT/tests/ansible/verify.yml"
    ansible-playbook "${options[@]}" -e "$components" "$ROOT/ansible/site.yml" | tee "$tmp/rerun.log"
    if ! grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' "$tmp/rerun.log"; then
        printf 'FAIL: second apply was not idempotent on %s\n' "$image" >&2
        exit 1
    fi
    ansible-playbook "${options[@]}" -e "$components" --check --diff "$ROOT/ansible/site.yml"

    if [[ "${TEST_DESKTOP:-0}" == 1 ]]; then
        ansible-playbook "${options[@]}" "$ROOT/tests/ansible/desktop-fixtures.yml"
        desktop='{"setup_components":["launcher","i3","keybindings","appearance"],"setup_gnome_keybindings":true}'
        ansible-playbook "${options[@]}" -e "$desktop" "$ROOT/ansible/site.yml"
        ansible-playbook "${options[@]}" "$ROOT/tests/ansible/desktop-verify.yml"
        ansible-playbook "${options[@]}" -e "$desktop" "$ROOT/ansible/site.yml" | tee "$tmp/desktop-rerun.log"
        grep -Eq 'changed=0[[:space:]]+unreachable=0[[:space:]]+failed=0' "$tmp/desktop-rerun.log"
    fi

    if [[ "$image" == archlinux:* ]]; then
        ansible-playbook "${options[@]}" "$ROOT/tests/ansible/omarchy-fixture.yml"
        ansible-playbook "${options[@]}" -e setup_profile=omarchy \
            -e '{"setup_remove":["nix"],"setup_add":["docker","nvidia","tailscale"]}' "$ROOT/ansible/site.yml"
        if ansible-playbook "${options[@]}" -e '{"setup_components":["launcher"]}' "$ROOT/ansible/site.yml" > "$tmp/guard.log" 2>&1; then
            printf 'FAIL: desktop role accepted on Omarchy fixture\n' >&2
            exit 1
        fi
        grep -q 'Omarchy owns its desktop' "$tmp/guard.log"
    fi
    printf 'PASS: %s install, configuration, ownership, idempotency, and check mode\n' "$image"
    docker rm -f "$container" >/dev/null
    container=""
done
