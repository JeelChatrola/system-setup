#!/usr/bin/env bash

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { printf 'ok - %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { printf 'not ok - %s\n' "$1"; FAIL=$((FAIL + 1)); }

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$actual" == "$expected" ]]; then pass "$name"; else
        fail "$name"
        printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual"
    fi
}

assert_success() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi
}

assert_failure() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then fail "$name"; else pass "$name"; fi
}

if [[ ! -r "$ROOT/lib/profiles.sh" || ! -r "$ROOT/lib/platform.sh" || ! -r "$ROOT/lib/supply-chain.sh" \
    || ! -r "$ROOT/lib/gruvbox-theme.sh" || ! -r "$ROOT/lib/repository-data.sh" ]]; then
    fail "resolver, platform, supply-chain, theme, and repository libraries exist"
    printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
    exit 1
fi

# shellcheck source=../lib/profiles.sh
source "$ROOT/lib/profiles.sh"
# shellcheck source=../lib/platform.sh
source "$ROOT/lib/platform.sh"
# shellcheck source=../lib/supply-chain.sh
source "$ROOT/lib/supply-chain.sh"
# shellcheck source=../lib/gruvbox-theme.sh
source "$ROOT/lib/gruvbox-theme.sh"
# shellcheck source=../lib/repository-data.sh
source "$ROOT/lib/repository-data.sh"
[[ ! -r "$ROOT/lib/nix-config.sh" ]] || source "$ROOT/lib/nix-config.sh"

assert_eq "base profile" "nix" "$(resolve_components base)"
assert_eq "personal profile" "nix ghostty launcher appearance flatpak" "$(resolve_components personal)"
assert_eq "workstation profile order" "nix docker ghostty launcher i3 keybindings appearance flatpak" "$(resolve_components workstation)"
assert_eq "server profile" "nix docker" "$(resolve_components server)"
assert_eq "add/remove/deduplicate canonical order" \
    "nix docker tailscale ghostty appearance flatpak nvtop" \
    "$(resolve_components personal docker tailscale nvtop docker --remove launcher)"
assert_failure "unknown profile" resolve_components nope
assert_failure "unknown addition" resolve_components base nope
assert_failure "unknown removal" resolve_components base --remove nope
validate_nvidia_without_docker() { PATH=/nonexistent validate_component_dependencies nix nvidia; }
assert_success "nvidia dependency resolution is static without Docker" validate_nvidia_without_docker
assert_success "nvidia accepts selected Docker" validate_component_dependencies nix docker nvidia

assert_success "Ubuntu 24.04 x86_64 supported" validate_platform ubuntu 24.04 noble x86_64 nix docker ghostty
assert_success "Ubuntu 24.04 aarch64 supported" validate_platform ubuntu 24.04 noble aarch64 nix docker ghostty
assert_success "Debian 12 x86_64 supported" validate_platform debian 12 bookworm x86_64 nix docker ghostty
assert_success "Debian 12 aarch64 supported" validate_platform debian 12 bookworm aarch64 nix docker ghostty
assert_failure "unsupported Ubuntu release" validate_platform ubuntu 22.04 jammy x86_64 nix
assert_failure "unsupported distribution" validate_platform fedora 42 unknown x86_64 nix
assert_failure "Ubuntu codename mismatch" validate_platform ubuntu 24.04 bookworm x86_64 nix
assert_failure "Debian codename mismatch" validate_platform debian 12 noble x86_64 nix
assert_failure "nvtop rejects aarch64" validate_platform debian 12 bookworm aarch64 nvtop
assert_failure "flatpak rejects aarch64" validate_platform debian 12 bookworm aarch64 flatpak

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

NIX_INSTALLED_BIN="$TMP/nix-installed-bin"
NIX_INSTALLED_HOME="$TMP/nix-installed-home"
mkdir "$NIX_INSTALLED_BIN" "$NIX_INSTALLED_HOME"
cat >"$NIX_INSTALLED_BIN/nix" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$NIX_INSTALLED_BIN/nix"
assert_success "Nix already-installed path preserves successful exit status" \
    env HOME="$NIX_INSTALLED_HOME" PATH="$NIX_INSTALLED_BIN:$PATH" "$ROOT/debian/install-nix.sh"

THEME_FIXTURE="$TMP/theme-fixture/Gruvbox-GTK-Theme-fixture/themes"
for source_dir in \
    assets/cinnamon assets/gnome-shell assets/gtk assets/gtk-2.0 assets/metacity-1 assets/xfwm4 \
    main/cinnamon main/gnome-shell main/gtk-2.0 main/gtk-3.0 main/gtk-4.0 main/metacity-1 main/plank main/xfwm4 \
    sass/gnome-shell; do
    mkdir -p "$THEME_FIXTURE/src/$source_dir"
done
touch \
    "$THEME_FIXTURE/src/main/gnome-shell/gnome-shell-Dark.scss" \
    "$THEME_FIXTURE/src/main/gtk-3.0/gtk-Dark.scss" \
    "$THEME_FIXTURE/src/main/gtk-4.0/gtk-Dark.scss" \
    "$THEME_FIXTURE/src/sass/_tweaks.scss" \
    "$THEME_FIXTURE/src/sass/gnome-shell/_common.scss"
printf '%s\n' '# fixture gtkrc helper' >"$THEME_FIXTURE/gtkrc.sh"
cat >"$THEME_FIXTURE/install.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >"$THEME_INSTALL_ARGS"
destination=
while (($#)); do
    if [[ "$1" == --dest ]]; then destination="$2"; shift 2; else shift; fi
done
theme="$destination/Gruvbox-Dark"
mkdir -p \
    "$theme/gtk-2.0/assets" "$theme/gtk-3.0/assets" "$theme/gtk-4.0/assets" \
    "$theme/gnome-shell/assets" "$theme/cinnamon/assets" "$theme/metacity-1/assets" \
    "$theme/xfwm4" "$theme/plank"
printf '%s\n' '[Desktop Entry]' >"$theme/index.theme"
printf '%s\n' 'gtk2' >"$theme/gtk-2.0/gtkrc"
printf '%s\n' 'asset' >"$theme/gtk-2.0/assets/button.png"
printf '%s\n' 'gtk3' >"$theme/gtk-3.0/gtk.css"
printf '%s\n' 'gtk3-dark' >"$theme/gtk-3.0/gtk-dark.css"
printf '%s\n' 'asset' >"$theme/gtk-3.0/assets/button.svg"
printf '%s\n' 'gtk4' >"$theme/gtk-4.0/gtk.css"
printf '%s\n' 'gtk4-dark' >"$theme/gtk-4.0/gtk-dark.css"
printf '%s\n' 'asset' >"$theme/gtk-4.0/assets/button.svg"
printf '%s\n' 'shell' >"$theme/gnome-shell/gnome-shell.css"
printf '%s\n' 'asset' >"$theme/gnome-shell/assets/panel.svg"
printf '%s\n' 'cinnamon' >"$theme/cinnamon/cinnamon.css"
printf '%s\n' 'asset' >"$theme/cinnamon/assets/panel.svg"
printf '%s\n' 'metacity' >"$theme/metacity-1/metacity-theme-3.xml"
printf '%s\n' 'asset' >"$theme/metacity-1/assets/close.svg"
printf '%s\n' 'xfwm' >"$theme/xfwm4/themerc"
printf '%s\n' 'asset' >"$theme/xfwm4/close.png"
printf '%s\n' 'plank' >"$theme/plank/dock.theme"
for scale in hdpi xhdpi; do
    mkdir -p "$destination/Gruvbox-Dark-$scale/xfwm4"
    printf '%s\n' 'xfwm' >"$destination/Gruvbox-Dark-$scale/xfwm4/themerc"
    printf '%s\n' 'asset' >"$destination/Gruvbox-Dark-$scale/xfwm4/close.png"
done
EOF
chmod +x "$THEME_FIXTURE/install.sh"
tar -czf "$TMP/theme-fixture.tar.gz" -C "$TMP/theme-fixture" Gruvbox-GTK-Theme-fixture
mkdir "$TMP/theme-extract"
tar -xzf "$TMP/theme-fixture.tar.gz" -C "$TMP/theme-extract"
THEME_SOURCE="$TMP/theme-extract/Gruvbox-GTK-Theme-fixture"
assert_success "theme source archive layout is accepted" validate_gruvbox_source_layout "$THEME_SOURCE"

PREBUILT_ONLY="$TMP/prebuilt-only"
mkdir -p "$PREBUILT_ONLY/themes/Gruvbox-Dark"
assert_failure "prebuilt-only theme archive is rejected" validate_gruvbox_source_layout "$PREBUILT_ONLY"

THEME_BIN="$TMP/theme-bin"
mkdir "$THEME_BIN"
cat >"$THEME_BIN/sassc" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$THEME_BIN/sassc"
THEME_BUILD="$TMP/theme-build"
THEME_INSTALL_ARGS="$TMP/theme-install.args"
export THEME_INSTALL_ARGS
mkdir "$THEME_BUILD"
build_theme_fixture() { PATH="$THEME_BIN:$PATH" build_gruvbox_theme "$THEME_SOURCE" "$THEME_BUILD"; }
assert_success "pinned installer builds staged default dark standard theme" build_theme_fixture
assert_eq "theme installer receives constrained noninteractive flags" \
    "--dest $THEME_BUILD --theme default --color dark --size standard" "$(<"$THEME_INSTALL_ARGS")"
assert_success "complete generated Gruvbox bundle is accepted" validate_gruvbox_bundle "$THEME_BUILD"
for scale in Gruvbox-Dark Gruvbox-Dark-hdpi Gruvbox-Dark-xhdpi; do
    [[ -d "$THEME_BUILD/$scale" ]] || fail "generated bundle retains $scale"
done

APPEARANCE_BIN="$TMP/appearance-bin"
APPEARANCE_HOME="$TMP/appearance-home"
APPEARANCE_ARCHIVE_ROOT="$TMP/appearance-archive/Gruvbox-GTK-Theme-578cd220b5ff6e86b078a6111d26bb20ec8c733f"
mkdir "$APPEARANCE_BIN" "$APPEARANCE_HOME"
mkdir -p "$(dirname "$APPEARANCE_ARCHIVE_ROOT")"
cp -a "$THEME_SOURCE" "$APPEARANCE_ARCHIVE_ROOT"
tar -czf "$TMP/appearance-theme.tar.gz" -C "$(dirname "$APPEARANCE_ARCHIVE_ROOT")" "$(basename "$APPEARANCE_ARCHIVE_ROOT")"
cat >"$APPEARANCE_BIN/apt" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$APPEARANCE_BIN/sudo" <<'EOF'
#!/bin/sh
exit 0
EOF
cat >"$APPEARANCE_BIN/curl" <<'EOF'
#!/bin/sh
output=
while [ "$#" -gt 0 ]; do
    if [ "$1" = --output ]; then
        output="$2"
        shift 2
    else
        shift
    fi
done
cp "$MOCK_THEME_ARCHIVE" "$output"
EOF
cat >"$APPEARANCE_BIN/sha256sum" <<'EOF'
#!/bin/sh
printf '%s  %s\n' f45da23a6c4123148cf8f78983e391a86c2e2ee1b7a80aa66790f148cb9619bd "$1"
EOF
cat >"$APPEARANCE_BIN/sassc" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$APPEARANCE_BIN"/*
assert_success "appearance success preserves successful exit status" \
    env HOME="$APPEARANCE_HOME" PATH="$APPEARANCE_BIN:$PATH" \
    MOCK_THEME_ARCHIVE="$TMP/appearance-theme.tar.gz" THEME_INSTALL_ARGS="$TMP/appearance-install.args" \
    "$ROOT/debian/setup-appearance.sh"

UNMANAGED_THEMES="$TMP/unmanaged-themes"
mkdir -p "$UNMANAGED_THEMES/user-theme"
printf '%s\n' 'user-owned bytes' >"$UNMANAGED_THEMES/user-theme/custom"
ln -s user-theme "$UNMANAGED_THEMES/Gruvbox-Dark"
UNMANAGED_BEFORE="$(sha256sum "$UNMANAGED_THEMES/user-theme/custom")"
UNMANAGED_LINK_BEFORE="$(readlink "$UNMANAGED_THEMES/Gruvbox-Dark")"
UNMANAGED_OUTPUT="$(refuse_unmanaged_gruvbox_stable "$UNMANAGED_THEMES" 2>&1)"
assert_failure "arbitrary Gruvbox symlink is refused" test "$?" -eq 0
assert_eq "arbitrary symlink target remains unchanged" "$UNMANAGED_LINK_BEFORE" \
    "$(readlink "$UNMANAGED_THEMES/Gruvbox-Dark")"
assert_eq "arbitrary symlink content remains byte-identical" "$UNMANAGED_BEFORE" \
    "$(sha256sum "$UNMANAGED_THEMES/user-theme/custom")"
if [[ "$UNMANAGED_OUTPUT" == *"Move or remove it manually, then rerun the appearance component"* ]]; then
    pass "unmanaged symlink refusal gives precise manual guidance"
else
    fail "unmanaged symlink refusal gives precise manual guidance"
fi

BROKEN_THEMES="$TMP/broken-themes"
mkdir "$BROKEN_THEMES"
ln -s missing-bundle/Gruvbox-Dark "$BROKEN_THEMES/Gruvbox-Dark"
assert_failure "broken Gruvbox symlink is refused" refuse_unmanaged_gruvbox_stable "$BROKEN_THEMES"
assert_eq "broken Gruvbox symlink remains unchanged" "missing-bundle/Gruvbox-Dark" \
    "$(readlink "$BROKEN_THEMES/Gruvbox-Dark")"

UNMANAGED_FILE_THEMES="$TMP/unmanaged-file-themes"
mkdir "$UNMANAGED_FILE_THEMES"
printf '%s\n' 'user-owned file' >"$UNMANAGED_FILE_THEMES/Gruvbox-Dark"
UNMANAGED_FILE_BEFORE="$(sha256sum "$UNMANAGED_FILE_THEMES/Gruvbox-Dark")"
assert_failure "unmanaged Gruvbox file is refused" refuse_unmanaged_gruvbox_stable "$UNMANAGED_FILE_THEMES"
assert_eq "unmanaged Gruvbox file remains byte-identical" "$UNMANAGED_FILE_BEFORE" \
    "$(sha256sum "$UNMANAGED_FILE_THEMES/Gruvbox-Dark")"

OWNED_THEMES="$TMP/owned-themes"
mkdir "$OWNED_THEMES"
cp -a "$THEME_BUILD" "$OWNED_THEMES/.system-setup-gruvbox-1111111111111111111111111111111111111111.old"
OLD_BUNDLE="$OWNED_THEMES/.system-setup-gruvbox-1111111111111111111111111111111111111111.old"
write_gruvbox_ownership_marker "$OLD_BUNDLE"
ln -s "$(basename "$OLD_BUNDLE")/Gruvbox-Dark" "$OWNED_THEMES/Gruvbox-Dark"
assert_success "marked previous installer symlink is replaceable" refuse_unmanaged_gruvbox_stable "$OWNED_THEMES"

cp -a "$THEME_BUILD" "$OWNED_THEMES/.system-setup-gruvbox-2222222222222222222222222222222222222222.new"
NEW_BUNDLE="$OWNED_THEMES/.system-setup-gruvbox-2222222222222222222222222222222222222222.new"
write_gruvbox_ownership_marker "$NEW_BUNDLE"
assert_success "complete marked bundle publishes stable theme" publish_gruvbox_stable_link "$OWNED_THEMES" "$NEW_BUNDLE"
assert_eq "stable theme atomically points into new bundle" "$(basename "$NEW_BUNDLE")/Gruvbox-Dark" \
    "$(readlink "$OWNED_THEMES/Gruvbox-Dark")"
assert_eq "no public hdpi stable name is created" "absent" \
    "$([[ -e "$OWNED_THEMES/Gruvbox-Dark-hdpi" || -L "$OWNED_THEMES/Gruvbox-Dark-hdpi" ]] && printf present || printf absent)"
assert_eq "no public xhdpi stable name is created" "absent" \
    "$([[ -e "$OWNED_THEMES/Gruvbox-Dark-xhdpi" || -L "$OWNED_THEMES/Gruvbox-Dark-xhdpi" ]] && printf present || printf absent)"

ACTIVE_LINK_BEFORE="$(readlink "$OWNED_THEMES/Gruvbox-Dark")"
ACTIVE_BUNDLE_BEFORE="$(sha256sum "$NEW_BUNDLE/Gruvbox-Dark/index.theme")"
cp -a "$THEME_BUILD" "$OWNED_THEMES/.system-setup-gruvbox-3333333333333333333333333333333333333333.candidate"
CANDIDATE_BUNDLE="$OWNED_THEMES/.system-setup-gruvbox-3333333333333333333333333333333333333333.candidate"
write_gruvbox_ownership_marker "$CANDIDATE_BUNDLE"
rm "$CANDIDATE_BUNDLE/Gruvbox-Dark-xhdpi/xfwm4/close.png"
assert_failure "incomplete candidate bundle is not published" publish_gruvbox_stable_link "$OWNED_THEMES" "$CANDIDATE_BUNDLE"
assert_eq "failed publication leaves stable symlink unchanged" "$ACTIVE_LINK_BEFORE" \
    "$(readlink "$OWNED_THEMES/Gruvbox-Dark")"
assert_eq "failed publication leaves active bundle byte-identical" "$ACTIVE_BUNDLE_BEFORE" \
    "$(sha256sum "$NEW_BUNDLE/Gruvbox-Dark/index.theme")"
assert_failure "incomplete generated Gruvbox sibling is rejected" validate_gruvbox_bundle "$CANDIDATE_BUNDLE"

MARKER_ATTACK_THEMES="$TMP/marker-attack-themes"
mkdir "$MARKER_ATTACK_THEMES"
cp -a "$THEME_BUILD" "$MARKER_ATTACK_THEMES/.system-setup-gruvbox-4444444444444444444444444444444444444444.attack"
ATTACK_BUNDLE="$MARKER_ATTACK_THEMES/.system-setup-gruvbox-4444444444444444444444444444444444444444.attack"
printf '%s\n' "$GRUVBOX_OWNER_MARKER_CONTENT" >"$MARKER_ATTACK_THEMES/attacker-marker"
ln -s ../attacker-marker "$ATTACK_BUNDLE/.system-setup-owner"
ln -s "$(basename "$ATTACK_BUNDLE")/Gruvbox-Dark" "$MARKER_ATTACK_THEMES/Gruvbox-Dark"
ATTACK_MARKER_BEFORE="$(sha256sum "$MARKER_ATTACK_THEMES/attacker-marker")"
assert_failure "symlinked ownership marker is refused" refuse_unmanaged_gruvbox_stable "$MARKER_ATTACK_THEMES"
assert_eq "attacker-controlled marker remains byte-identical" "$ATTACK_MARKER_BEFORE" \
    "$(sha256sum "$MARKER_ATTACK_THEMES/attacker-marker")"

SUPPLY_BIN="$TMP/supply-bin"
mkdir "$SUPPLY_BIN"
cat >"$SUPPLY_BIN/curl" <<'EOF'
#!/bin/sh
output=
while [ "$#" -gt 0 ]; do
    if [ "$1" = --output ]; then
        output="$2"
        shift 2
    else
        shift
    fi
done
cp "$MOCK_CURL_SOURCE" "$output"
EOF
chmod +x "$SUPPLY_BIN/curl"
printf '%s\n' 'trusted fixture' >"$TMP/trusted-download"
printf '%s\n' 'corrupt fixture' >"$TMP/corrupt-download"
TRUSTED_SHA256="$(sha256sum "$TMP/trusted-download" | cut -d' ' -f1)"
printf '%s\n' 'existing wallpaper' >"$TMP/wallpaper.jpg"
download_fixture() {
    PATH="$SUPPLY_BIN:$PATH" MOCK_CURL_SOURCE="$1" download_verified_file fixture://wallpaper "$TRUSTED_SHA256" "$2"
}
assert_failure "checksum mismatch rejects downloaded fixture" download_fixture "$TMP/corrupt-download" "$TMP/wallpaper.jpg"
assert_eq "checksum mismatch preserves existing destination" "existing wallpaper" "$(<"$TMP/wallpaper.jpg")"
assert_failure "checksum mismatch rejects absent destination" download_fixture "$TMP/corrupt-download" "$TMP/absent-wallpaper.jpg"
assert_eq "checksum mismatch leaves absent destination absent" "absent" "$([[ -e "$TMP/absent-wallpaper.jpg" ]] && printf present || printf absent)"
assert_success "verified fixture is atomically installed" download_fixture "$TMP/trusted-download" "$TMP/wallpaper.jpg"
assert_eq "verified fixture replaces destination" "trusted fixture" "$(<"$TMP/wallpaper.jpg")"

assert_eq "fingerprint normalization removes whitespace and uppercases" \
    "9DC858229FC7DD38854AE2D88D81803C0EBFCD88" \
    "$(normalize_fingerprint '9dc8 5822 9fc7 dd38 854a e2d8 8d81 803c 0ebf cd88')"
assert_failure "fingerprint normalization rejects non-hex input" normalize_fingerprint 'not-a-fingerprint'

KEY_GPG_BIN="$TMP/key-gpg-bin"
mkdir "$KEY_GPG_BIN"
cat >"$KEY_GPG_BIN/gpg" <<'EOF'
#!/bin/sh
printf 'pub:-:4096:1:0000000000000000:0:0::::::\n'
printf 'fpr:::::::::%s:\n' "$MOCK_KEY_FINGERPRINT"
EOF
chmod +x "$KEY_GPG_BIN/gpg"
touch "$TMP/repository-key"
verify_fixture_key() {
    PATH="$KEY_GPG_BIN:$PATH" MOCK_KEY_FINGERPRINT="$1" \
        verify_openpgp_fingerprint "$TMP/repository-key" 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
}
assert_success "expected repository key fingerprint is accepted" verify_fixture_key 9DC858229FC7DD38854AE2D88D81803C0EBFCD88
assert_failure "unexpected repository key fingerprint is rejected" verify_fixture_key 0000000000000000000000000000000000000000

printf '%s\n' \
    "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" \
    "#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/experimental/deb/\$(ARCH) /" \
    >"$TMP/nvidia-valid.list"
assert_success "strict NVIDIA repository definition is accepted" validate_nvidia_repository_file "$TMP/nvidia-valid.list"
printf '%s\n' \
    "deb https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" \
    "#deb https://nvidia.github.io/libnvidia-container/experimental/deb/\$(ARCH) /" \
    >"$TMP/nvidia-download.list"
assert_success "representative NVIDIA repository data is staged and validated" \
    prepare_nvidia_repository_file "$TMP/nvidia-download.list" "$TMP/nvidia-staged.list"
assert_eq "NVIDIA stable and commented experimental entries use the keyring" \
    "$(<"$TMP/nvidia-valid.list")" "$(<"$TMP/nvidia-staged.list")"
printf '%s\n' "deb [trusted=yes] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" >"$TMP/nvidia-malicious.list"
assert_failure "NVIDIA trusted=yes repository definition is rejected" validate_nvidia_repository_file "$TMP/nvidia-malicious.list"
printf '%s\n' "deb https://evil.example/stable/deb/\$(ARCH) /" >"$TMP/nvidia-domain.list"
assert_failure "NVIDIA unexpected repository domain is rejected" validate_nvidia_repository_file "$TMP/nvidia-domain.list"
printf '%s\n' 'Types: deb' >"$TMP/nvidia-malformed.list"
assert_failure "malformed NVIDIA repository definition is rejected" validate_nvidia_repository_file "$TMP/nvidia-malformed.list"
printf '%s\n' \
    "deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/stable/deb/\$(ARCH) /" \
    "#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://nvidia.github.io/libnvidia-container/experimental/deb/\$(ARCH) /" \
    "deb https://evil.example/stable/deb/\$(ARCH) /" >"$TMP/nvidia-extra.list"
assert_failure "NVIDIA extra active repository line is rejected" validate_nvidia_repository_file "$TMP/nvidia-extra.list"

printf '%s\n' 'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bookworm main' >"$TMP/tailscale-valid.list"
assert_success "strict Tailscale repository definition is accepted" \
    validate_tailscale_repository_file "$TMP/tailscale-valid.list" debian bookworm
printf '%s\n' 'deb [trusted=yes signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bookworm main' >"$TMP/tailscale-malicious.list"
assert_failure "Tailscale trusted=yes repository definition is rejected" \
    validate_tailscale_repository_file "$TMP/tailscale-malicious.list" debian bookworm
printf '%s\n' 'deb [signed-by=/tmp/untrusted.gpg] https://pkgs.tailscale.com/stable/debian bookworm main' >"$TMP/tailscale-signed-by.list"
assert_failure "Tailscale unexpected signed-by policy is rejected" \
    validate_tailscale_repository_file "$TMP/tailscale-signed-by.list" debian bookworm
printf '%s\n' 'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://evil.example/debian bookworm main' >"$TMP/tailscale-domain.list"
assert_failure "Tailscale unexpected repository domain is rejected" \
    validate_tailscale_repository_file "$TMP/tailscale-domain.list" debian bookworm
printf '%s\n' 'not a deb line' >"$TMP/tailscale-malformed.list"
assert_failure "malformed Tailscale repository definition is rejected" \
    validate_tailscale_repository_file "$TMP/tailscale-malformed.list" debian bookworm
printf '%s\n' \
    'deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bookworm main' \
    'deb https://evil.example/debian bookworm main' >"$TMP/tailscale-extra.list"
assert_failure "Tailscale extra active repository line is rejected" \
    validate_tailscale_repository_file "$TMP/tailscale-extra.list" debian bookworm
cat >"$TMP/os-release" <<'EOF'
ID=debian
VERSION_ID="12"
VERSION_CODENAME=bookworm
EOF
cat >"$TMP/malicious-os-release" <<EOF
ID=debian
VERSION_ID=12
VERSION_CODENAME=bookworm
MALICIOUS=\$(touch "$TMP/os-release-executed")
EOF
mkdir "$TMP/bin"
mkdir "$TMP/home"
for command_name in sudo curl apt-get wget ping nc getent; do
    cat >"$TMP/bin/$command_name" <<EOF
#!/bin/sh
touch "$TMP/mutated"
exit 99
EOF
    chmod +x "$TMP/bin/$command_name"
done

PLAN_OUTPUT="$(PATH="$TMP/bin:$PATH" HOME="$TMP/home" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    "$ROOT/install.sh" --profile personal --add docker --remove launcher --plan 2>&1)"
PLAN_STATUS=$?
assert_eq "plan succeeds" "0" "$PLAN_STATUS"
assert_eq "plan does not dispatch or invoke privileged/network tools" "absent" "$([[ -e "$TMP/mutated" ]] && printf present || printf absent)"
shopt -s nullglob dotglob
home_entries=("$TMP/home"/*)
shopt -u nullglob dotglob
if ((${#home_entries[@]} == 0)); then pass "plan does not write HOME"; else fail "plan does not write HOME"; fi
if [[ "$PLAN_OUTPUT" == *"OS: debian 12 (x86_64)"* && "$PLAN_OUTPUT" == *"Profile: personal"* \
    && "$PLAN_OUTPUT" == *"Components: nix docker ghostty appearance"* ]]; then
    pass "plan prints platform, selection, and ordered components"
else
    fail "plan prints platform, selection, and ordered components"
fi

FRESH_PLAN_PATH="$TMP/fresh-plan-bin"
mkdir "$FRESH_PLAN_PATH"
ln -s /usr/bin/bash "$FRESH_PLAN_PATH/bash"
ln -s /usr/bin/dirname "$FRESH_PLAN_PATH/dirname"
ln -s /usr/bin/uname "$FRESH_PLAN_PATH/uname"
FRESH_NVIDIA_PLAN="$(PATH="$FRESH_PLAN_PATH" HOME="$TMP/home" SYSTEM_SETUP_TEST_MODE=1 \
    SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    "$ROOT/install.sh" --component nvidia --plan 2>&1)"
assert_eq "nvidia plan succeeds on fresh PATH without Docker" "0" "$?"
if [[ "$FRESH_NVIDIA_PLAN" == *"runtime dependency checks deferred"* ]]; then
    pass "fresh NVIDIA plan states runtime check deferred"
else
    fail "fresh NVIDIA plan states runtime check deferred"
fi

rm -f "$TMP/mutated"
cat >"$TMP/bin/docker" <<EOF
#!/bin/sh
touch "$TMP/docker-executed"
exit 0
EOF
chmod +x "$TMP/bin/docker"
NVIDIA_PLAN="$(PATH="$TMP/bin:$PATH" HOME="$TMP/home" SYSTEM_SETUP_TEST_MODE=1 \
    SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    "$ROOT/install.sh" --component nvidia --plan 2>&1)"
assert_eq "nvidia plan with existing Docker command succeeds statically" "0" "$?"
assert_eq "plan never executes docker" "absent" "$([[ -e "$TMP/docker-executed" ]] && printf present || printf absent)"
assert_eq "plan never executes network or mutation commands" "absent" "$([[ -e "$TMP/mutated" ]] && printf present || printf absent)"
if [[ "$NVIDIA_PLAN" == *"runtime dependency checks deferred"* ]]; then
    pass "plan states runtime dependency checks are deferred"
else
    fail "plan states runtime dependency checks are deferred"
fi

SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/malicious-os-release" SYSTEM_SETUP_ARCH=x86_64 detect_platform
assert_eq "os-release is parsed as data, not executed" "absent" "$([[ -e "$TMP/os-release-executed" ]] && printf present || printf absent)"
assert_eq "test-mode os-release parser reads ID" "debian" "$PLATFORM_ID"
assert_eq "production ignores os-release override" "/etc/os-release" "$(SYSTEM_SETUP_TEST_MODE=0 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" platform_os_release_path)"
assert_eq "production ignores architecture override" "$(normalize_arch "$(uname -m)")" "$(SYSTEM_SETUP_TEST_MODE=0 SYSTEM_SETUP_ARCH=bogus platform_arch)"

assert_failure "direct root apply context rejected" validate_target_context 0 jeel "$TMP/home" jeel
assert_failure "HOME owner mismatch rejected" validate_target_context 1000 jeel "$TMP/home" another
assert_success "non-root owned HOME accepted" validate_target_context 1000 jeel "$TMP/home" jeel
if ((EUID == 0)); then
    rm -f "$TMP/mutated"
    ROOT_APPLY_OUTPUT="$(PATH="$TMP/bin:$PATH" HOME="$TMP/home" SYSTEM_SETUP_TEST_MODE=1 \
        SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
        "$ROOT/install.sh" --component nix --yes 2>&1)"
    assert_failure "top-level apply refuses direct root" test "$?" -eq 0
    if [[ "$ROOT_APPLY_OUTPUT" == *"Do not run this installer as root"* ]]; then
        pass "root refusal gives non-root sudo guidance"
    else
        fail "root refusal gives non-root sudo guidance"
    fi
    assert_eq "root refusal occurs before mutation commands" "absent" "$([[ -e "$TMP/mutated" ]] && printf present || printf absent)"
fi

NIX_CONFIG_TEST="$TMP/nix.conf"
printf '%s\n' 'experimental-features = flakes' >"$NIX_CONFIG_TEST"
if declare -F ensure_nix_features >/dev/null; then ensure_nix_features "$NIX_CONFIG_TEST"; fi
if grep -Eq '^experimental-features = .*nix-command.*flakes|^experimental-features = .*flakes.*nix-command' "$NIX_CONFIG_TEST"; then
    pass "Nix config repairs flakes-only feature line"
else
    fail "Nix config repairs flakes-only feature line"
fi
printf '%s\n' 'experimental-features = flakes # existing comment' >"$NIX_CONFIG_TEST"
ensure_nix_features "$NIX_CONFIG_TEST"
if grep -Eq '^experimental-features = ([^#]* )?nix-command( [^#]*)? flakes|^experimental-features = ([^#]* )?flakes( [^#]*)? nix-command' "$NIX_CONFIG_TEST"; then
    pass "Nix feature repair handles inline comments"
else
    fail "Nix feature repair handles inline comments"
fi
printf '%s\n' 'experimental-features = flakes flakes nix-command nix-command' >"$NIX_CONFIG_TEST"
ensure_nix_features "$NIX_CONFIG_TEST"
assert_eq "Nix feature repair deduplicates tokens" "experimental-features = flakes nix-command" "$(<"$NIX_CONFIG_TEST")"
printf '%s\n' 'keep-outputs = true' >"$NIX_CONFIG_TEST"
ensure_nix_features "$NIX_CONFIG_TEST"
if grep -Fxq 'experimental-features = nix-command flakes' "$NIX_CONFIG_TEST"; then pass "Nix feature repair adds missing line"; else fail "Nix feature repair adds missing line"; fi

RUNTIME_PATH="$TMP/runtime-bin"
mkdir "$RUNTIME_PATH"
ln -s /usr/bin/bash "$RUNTIME_PATH/bash"
ln -s /usr/bin/readlink "$RUNTIME_PATH/readlink"
cat >"$RUNTIME_PATH/ghostty" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$RUNTIME_PATH/ghostty"
runtime_i3_without_rofi() { PATH="$RUNTIME_PATH" validate_runtime_dependencies apply i3; }
assert_failure "standalone i3 apply rejects missing Rofi" runtime_i3_without_rofi
assert_success "i3 apply accepts selected launcher" validate_runtime_dependencies apply launcher i3

MOCKBIN="$TMP/mock-bin"
CALL_LOG="$TMP/calls.log"
mkdir "$MOCKBIN"
export CALL_LOG
cat >"$MOCKBIN/sudo" <<'EOF'
#!/bin/sh
printf 'sudo %s\n' "$*" >>"$CALL_LOG"
case "${1:-}" in docker|nvidia-ctk|sha256sum) exec "$@" ;; esac
exit 0
EOF
cat >"$MOCKBIN/docker" <<'EOF'
#!/bin/sh
printf 'docker %s\n' "$*" >>"$CALL_LOG"
if [ "${1:-}" = info ] && [ "${MOCK_DOCKER_INFO_FAIL:-0}" = 1 ]; then exit 42; fi
exit 0
EOF
cat >"$MOCKBIN/apt-get" <<'EOF'
#!/bin/sh
printf 'apt-get %s\n' "$*" >>"$CALL_LOG"
exit 0
EOF
cat >"$MOCKBIN/curl" <<'EOF'
#!/bin/sh
printf 'curl %s\n' "$*" >>"$CALL_LOG"
[ "${DOCKER_FAIL_STAGE:-}" != download ] || exit 22
output=
url=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --output) output="$2"; shift 2 ;;
        http*) url="$1"; shift ;;
        *) shift ;;
    esac
done
case "$url" in
    *nvidia-container-toolkit.list)
        if [ -n "${MOCK_NVIDIA_REPOSITORY_URL_LOG:-}" ]; then printf '%s\n' "$url" >"$MOCK_NVIDIA_REPOSITORY_URL_LOG"; fi
        if [ "${MOCK_NVIDIA_REPOSITORY_DOWNLOAD_FAIL:-0}" = 1 ]; then exit 22; fi
        content="${MOCK_REPOSITORY_CONTENT:-$(printf '%s\n' \
            'deb https://nvidia.github.io/libnvidia-container/stable/deb/$(ARCH) /' \
            '#deb https://nvidia.github.io/libnvidia-container/experimental/deb/$(ARCH) /')}" ;;
    *.tailscale-keyring.list)
        content="${MOCK_REPOSITORY_CONTENT:-deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/debian bookworm main}" ;;
    *) content='mock-key' ;;
esac
if [ -n "$output" ]; then printf '%s\n' "$content" >"$output"; else printf '%s\n' "$content"; fi
EOF
cat >"$MOCKBIN/gpg" <<'EOF'
#!/bin/sh
for argument do
    if [ "$argument" = --show-keys ]; then
        printf 'pub:-:4096:1:0000000000000000:0:0::::::\n'
        if [ "${DOCKER_FAIL_STAGE:-}" = fingerprint ]; then
            printf 'fpr:::::::::0000000000000000000000000000000000000000:\n'
        else
            printf 'fpr:::::::::%s:\n' "${MOCK_KEY_FINGERPRINT:-9DC858229FC7DD38854AE2D88D81803C0EBFCD88}"
        fi
        exit 0
    fi
done
[ "${DOCKER_FAIL_STAGE:-}" != dearmor ] || exit 1
cat
EOF
cat >"$MOCKBIN/dpkg" <<'EOF'
#!/bin/sh
printf 'amd64\n'
EOF
cat >"$MOCKBIN/systemctl" <<'EOF'
#!/bin/sh
printf 'systemctl %s\n' "$*" >>"$CALL_LOG"
exit 0
EOF
cat >"$MOCKBIN/nvidia-ctk" <<'EOF'
#!/bin/sh
printf 'nvidia-ctk %s\n' "$*" >>"$CALL_LOG"
if [ "${1:-}" = runtime ] && [ -n "${NVIDIA_DAEMON_JSON:-}" ]; then printf '%s\n' changed >"$NVIDIA_DAEMON_JSON"; fi
exit 0
EOF
cat >"$MOCKBIN/lspci" <<'EOF'
#!/bin/sh
printf 'NVIDIA Corporation Device\n'
EOF
chmod +x "$MOCKBIN"/*
NVIDIA_INSTALL_BIN="$TMP/nvidia-install-bin"
mkdir "$NVIDIA_INSTALL_BIN"
for command_name in apt-get curl docker gpg lspci sudo; do
    ln -s "$MOCKBIN/$command_name" "$NVIDIA_INSTALL_BIN/$command_name"
done
for command_name in bash dirname grep mktemp rm sed; do
    ln -s "$(command -v "$command_name")" "$NVIDIA_INSTALL_BIN/$command_name"
done

call_before() {
    local first="$1" second="$2" first_line second_line
    first_line="$(grep -n -m1 "$first" "$CALL_LOG" | cut -d: -f1)"
    second_line="$(grep -n -m1 "$second" "$CALL_LOG" | cut -d: -f1)"
    [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]]
}

DOCKER_BIN="$TMP/docker-bin"
DOCKER_TEST_ROOT="$TMP/docker-root"
export DOCKER_TEST_ROOT
mkdir -p "$DOCKER_BIN" "$DOCKER_TEST_ROOT/etc/apt/sources.list.d" "$DOCKER_TEST_ROOT/tmp"
cat >"$DOCKER_BIN/sudo" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'sudo %s\n' "$*" >>"$CALL_LOG"
operation="$1"
shift
case "$operation" in
    apt-get)
        case "${DOCKER_FAIL_STAGE:-}:$*" in
            dependency-update:update|dependencies:install*ca-certificates*|packages:install*docker-ce*) exit 42 ;;
        esac
        # Both stale source forms must be absent during dependency setup.
        if [[ "$*" == 'install -y ca-certificates curl gnupg' ]]; then
            for name in docker.list docker.sources; do
                [[ ! -e "$DOCKER_TEST_ROOT/etc/apt/sources.list.d/$name" && ! -L "$DOCKER_TEST_ROOT/etc/apt/sources.list.d/$name" ]] || exit 43
            done
        fi
        exit 0 ;;
    docker) exec docker "$@" ;;
    systemctl|usermod) exit 0 ;;
    sh|mktemp|mv|install|rm|rmdir) ;;
    *) exit 99 ;;
esac
arguments=()
for argument do
    case "$argument" in
        /etc/apt/*) argument="$DOCKER_TEST_ROOT$argument" ;;
        "$DOCKER_TEST_ROOT"/*) ;;
        /*) printf 'Unsafe mock path: %s\n' "$argument" >&2; exit 99 ;;
    esac
    arguments+=("$argument")
done
case "${DOCKER_FAIL_STAGE:-}:$operation:$*" in
    probe:sh:*' sh /etc/apt/sources.list.d/docker.sources') exit 1 ;;
    backup:mv:*docker.sources*|keyring:install:*docker.gpg|stage:install:*replacement|publish:mv:*replacement*) exit 42 ;;
    interrupt-*:mv:*replacement*)
        "$operation" "${arguments[@]}"
        kill -s "${DOCKER_FAIL_STAGE#interrupt-}" "$PPID"
        exit 0 ;;
esac
exec "$operation" "${arguments[@]}"
EOF
chmod +x "$DOCKER_BIN/sudo"

: >"$CALL_LOG"
printf '%s\n' 'old list' >"$DOCKER_TEST_ROOT/etc/apt/sources.list.d/docker.list"
printf '%s\n' 'old sources' >"$DOCKER_TEST_ROOT/etc/apt/sources.list.d/docker.sources"
PATH="$DOCKER_BIN:$MOCKBIN:$PATH" TMPDIR="$DOCKER_TEST_ROOT/tmp" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_ADD_DOCKER_GROUP=0 "$ROOT/debian/install-docker.sh" >/dev/null 2>&1
DOCKER_MOCK_STATUS=$?
assert_eq "mocked Docker apply succeeds" "0" "$DOCKER_MOCK_STATUS"
DOCKER_EXPECTED_SOURCE='deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable'
assert_eq "Docker publishes the verified replacement source" "$DOCKER_EXPECTED_SOURCE" \
    "$(<"$DOCKER_TEST_ROOT/etc/apt/sources.list.d/docker.list")"
assert_success "Docker retires the previous deb822 source on success" \
    test ! -e "$DOCKER_TEST_ROOT/etc/apt/sources.list.d/docker.sources"
if grep -q 'apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin' "$CALL_LOG"; then
    pass "Docker always converges official packages and Compose"
else
    fail "Docker always converges official packages and Compose"
fi
if grep -q 'curl .*download.docker.com/linux/debian/gpg' "$CALL_LOG"; then pass "Docker converges official repository"; else fail "Docker converges official repository"; fi
if grep -q 'sudo mv -T /etc/apt/sources.list.d/docker.sources ' "$CALL_LOG"; then
    pass "Docker neutralizes both owned stale source forms"
else
    fail "Docker neutralizes both owned stale source forms"
fi
if call_before 'sudo mv -T /etc/apt/sources.list.d/docker.sources ' 'sudo apt-get update'; then
    pass "Docker neutralizes stale sources before first apt update"
else
    fail "Docker neutralizes stale sources before first apt update"
fi
if grep -q 'sudo systemctl enable --now docker' "$CALL_LOG"; then pass "Docker converges systemd service"; else fail "Docker converges systemd service"; fi
if grep -q '^sudo docker info$' "$CALL_LOG"; then pass "Docker verifies daemon with privileged access"; else fail "Docker verifies daemon with privileged access"; fi

: >"$CALL_LOG"
if PATH="$DOCKER_BIN:$MOCKBIN:$PATH" TMPDIR="$DOCKER_TEST_ROOT/tmp" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_ADD_DOCKER_GROUP=0 MOCK_DOCKER_INFO_FAIL=1 \
    "$ROOT/debian/install-docker.sh" >/dev/null 2>&1; then
    fail "Docker daemon verification failure propagates"
else
    pass "Docker daemon verification failure propagates"
fi

: >"$CALL_LOG"
if PATH="$DOCKER_BIN:$MOCKBIN:$PATH" TMPDIR="$DOCKER_TEST_ROOT/tmp" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_ADD_DOCKER_GROUP=0 \
    MOCK_KEY_FINGERPRINT=0000000000000000000000000000000000000000 \
    "$ROOT/debian/install-docker.sh" >/dev/null 2>&1; then
    fail "Docker rejects a repository key fingerprint mismatch"
else
    pass "Docker rejects a repository key fingerprint mismatch"
fi
if grep -q '^sudo install .*docker.gpg\|^sudo mv .*replacement /etc/apt/sources.list.d/docker.list$' "$CALL_LOG"; then
    fail "Docker key mismatch aborts before keyring and source installation"
else
    pass "Docker key mismatch aborts before keyring and source installation"
fi

for docker_layout in regular symlinks absent sources-only; do
    for docker_stage in probe backup dependency-update dependencies download fingerprint dearmor keyring stage publish interrupt-TERM interrupt-INT; do
        [[ "$docker_layout:$docker_stage" != absent:backup ]] || continue
        docker_sources="$DOCKER_TEST_ROOT/etc/apt/sources.list.d"
        rm -rf "$docker_sources"
        mkdir "$docker_sources"
        case "$docker_layout" in
            regular)
                printf '%s\n' 'previous list bytes' >"$docker_sources/docker.list"
                printf '%s\n' 'previous deb822 bytes' >"$docker_sources/docker.sources"
                chmod 0640 "$docker_sources/docker.list"
                chmod 0600 "$docker_sources/docker.sources" ;;
            symlinks)
                printf '%s\n' 'symlink target bytes' >"$docker_sources/target"
                ln -s target "$docker_sources/docker.list"
                ln -s missing-target "$docker_sources/docker.sources" ;;
            sources-only)
                printf '%s\n' 'previous deb822 bytes' >"$docker_sources/docker.sources"
                chmod 0600 "$docker_sources/docker.sources" ;;
        esac
        cp -a "$docker_sources" "$DOCKER_TEST_ROOT/expected"
        docker_metadata_before="$(stat -c '%n %a %u %g %i' "$docker_sources"/* 2>/dev/null || true)"
        : >"$CALL_LOG"
        if env PATH="$DOCKER_BIN:$MOCKBIN:$PATH" TMPDIR="$DOCKER_TEST_ROOT/tmp" \
            SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
            SYSTEM_SETUP_HAS_SYSTEMD=0 SYSTEM_SETUP_ADD_DOCKER_GROUP=0 DOCKER_FAIL_STAGE="$docker_stage" \
            "$ROOT/debian/install-docker.sh" >/dev/null 2>&1; then
            docker_status=0
        else
            docker_status=$?
        fi
        case "$docker_stage" in
            interrupt-TERM) assert_eq "Docker TERM interruption propagates ($docker_layout)" 143 "$docker_status" ;;
            interrupt-INT) assert_eq "Docker INT interruption propagates ($docker_layout)" 130 "$docker_status" ;;
            *) assert_failure "Docker $docker_stage failure propagates ($docker_layout)" test "$docker_status" -eq 0 ;;
        esac
        if [[ "$docker_stage" == probe ]]; then
            assert_failure "Docker probe error aborts before APT ($docker_layout)" grep -q 'sudo apt-get' "$CALL_LOG"
        fi
        # diff cannot compare dangling links, so compare those explicitly.
        if [[ "$docker_layout" == symlinks ]]; then
            assert_eq "Docker $docker_stage preserves source symlink" target "$(readlink "$docker_sources/docker.list")"
            assert_eq "Docker $docker_stage preserves dangling symlink" missing-target "$(readlink "$docker_sources/docker.sources")"
            assert_success "Docker $docker_stage preserves symlink target contents" \
                cmp "$DOCKER_TEST_ROOT/expected/target" "$docker_sources/target"
        else
            assert_success "Docker $docker_stage preserves source contents ($docker_layout)" \
                diff -r "$DOCKER_TEST_ROOT/expected" "$docker_sources"
        fi
        assert_eq "Docker $docker_stage preserves modes, owners and inodes ($docker_layout)" \
            "$docker_metadata_before" "$(stat -c '%n %a %u %g %i' "$docker_sources"/* 2>/dev/null || true)"
        assert_eq "Docker $docker_stage cleans temporary backups ($docker_layout)" "" \
            "$(compgen -G "$docker_sources/.docker-backup.*")"
        rm -rf "$DOCKER_TEST_ROOT/expected"
    done
done

assert_failure "Docker package failure after publication propagates" \
    env PATH="$DOCKER_BIN:$MOCKBIN:$PATH" TMPDIR="$DOCKER_TEST_ROOT/tmp" \
    SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    SYSTEM_SETUP_HAS_SYSTEMD=0 SYSTEM_SETUP_ADD_DOCKER_GROUP=0 DOCKER_FAIL_STAGE=packages \
    "$ROOT/debian/install-docker.sh"
assert_eq "Docker keeps the verified replacement after publication" "$DOCKER_EXPECTED_SOURCE" \
    "$(<"$DOCKER_TEST_ROOT/etc/apt/sources.list.d/docker.list")"

: >"$CALL_LOG"
NVIDIA_DAEMON_JSON="$TMP/daemon.json"
export NVIDIA_DAEMON_JSON
printf '%s\n' original >"$NVIDIA_DAEMON_JSON"
PATH="$MOCKBIN:$PATH" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_YES=1 SYSTEM_SETUP_DOCKER_DAEMON_JSON="$NVIDIA_DAEMON_JSON" \
    "$ROOT/debian/install-nvidia-toolkit.sh" >/dev/null 2>&1
NVIDIA_MOCK_STATUS=$?
assert_eq "mocked NVIDIA apply succeeds" "0" "$NVIDIA_MOCK_STATUS"
if grep -q '^sudo nvidia-ctk runtime configure --runtime=docker$' "$CALL_LOG"; then pass "NVIDIA always converges Docker runtime"; else fail "NVIDIA always converges Docker runtime"; fi
if call_before '^sudo nvidia-ctk runtime configure --runtime=docker$' '^sudo systemctl restart docker$'; then pass "NVIDIA restarts Docker after runtime configuration changes"; else fail "NVIDIA restarts Docker after runtime configuration changes"; fi
if grep -q '^sudo docker info$' "$CALL_LOG"; then pass "NVIDIA verifies Docker with privileged access"; else fail "NVIDIA verifies Docker with privileged access"; fi

: >"$CALL_LOG"
printf '%s\n' original >"$NVIDIA_DAEMON_JSON"
if PATH="$MOCKBIN:$PATH" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_YES=1 SYSTEM_SETUP_DOCKER_DAEMON_JSON="$NVIDIA_DAEMON_JSON" \
    MOCK_DOCKER_INFO_FAIL=1 "$ROOT/debian/install-nvidia-toolkit.sh" >/dev/null 2>&1; then
    fail "NVIDIA privileged Docker verification failure propagates"
else
    pass "NVIDIA privileged Docker verification failure propagates"
fi

mv "$MOCKBIN/nvidia-ctk" "$TMP/nvidia-ctk.mock"
: >"$CALL_LOG"
if PATH="$NVIDIA_INSTALL_BIN" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_YES=1 \
    MOCK_KEY_FINGERPRINT=0000000000000000000000000000000000000000 \
    "$ROOT/debian/install-nvidia-toolkit.sh" >/dev/null 2>&1; then
    fail "NVIDIA rejects a repository key fingerprint mismatch"
else
    pass "NVIDIA rejects a repository key fingerprint mismatch"
fi
if grep -q '/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg\|/etc/apt/sources.list.d/nvidia-container-toolkit.list' "$CALL_LOG"; then
    fail "NVIDIA key mismatch aborts before keyring and source installation"
else
    pass "NVIDIA key mismatch aborts before keyring and source installation"
fi
mv "$TMP/nvidia-ctk.mock" "$MOCKBIN/nvidia-ctk"

mv "$MOCKBIN/nvidia-ctk" "$TMP/nvidia-ctk.mock"
: >"$CALL_LOG"
NVIDIA_REPOSITORY_URL_LOG="$TMP/nvidia-repository-url.log"
if PATH="$NVIDIA_INSTALL_BIN" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_YES=1 \
    MOCK_KEY_FINGERPRINT=C95B321B61E88C1809C4F759DDCAE044F796ECB0 \
    MOCK_NVIDIA_REPOSITORY_URL_LOG="$NVIDIA_REPOSITORY_URL_LOG" \
    MOCK_NVIDIA_REPOSITORY_DOWNLOAD_FAIL=1 \
    "$ROOT/debian/install-nvidia-toolkit.sh" >/dev/null 2>&1; then
    fail "NVIDIA repository download failure propagates"
else
    pass "NVIDIA repository download failure propagates"
fi
assert_eq "NVIDIA requests the documented generic stable deb repository endpoint" \
    "https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list" \
    "$(<"$NVIDIA_REPOSITORY_URL_LOG")"
if grep -q '/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg\|/etc/apt/sources.list.d/nvidia-container-toolkit.list' "$CALL_LOG"; then
    fail "failed NVIDIA repository download aborts before privileged replacement"
else
    pass "failed NVIDIA repository download aborts before privileged replacement"
fi
mv "$TMP/nvidia-ctk.mock" "$MOCKBIN/nvidia-ctk"

mv "$MOCKBIN/nvidia-ctk" "$TMP/nvidia-ctk.mock"
: >"$CALL_LOG"
if PATH="$NVIDIA_INSTALL_BIN" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" SYSTEM_SETUP_ARCH=x86_64 \
    SYSTEM_SETUP_HAS_SYSTEMD=1 SYSTEM_SETUP_YES=1 \
    MOCK_KEY_FINGERPRINT=C95B321B61E88C1809C4F759DDCAE044F796ECB0 \
    MOCK_REPOSITORY_CONTENT="deb [trusted=yes] https://evil.example/stable/deb/\$(ARCH) /" \
    "$ROOT/debian/install-nvidia-toolkit.sh" >/dev/null 2>&1; then
    fail "NVIDIA rejects malicious downloaded repository data"
else
    pass "NVIDIA rejects malicious downloaded repository data"
fi
if grep -q '/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg\|/etc/apt/sources.list.d/nvidia-container-toolkit.list' "$CALL_LOG"; then
    fail "malicious NVIDIA repository data aborts before keyring and source installation"
else
    pass "malicious NVIDIA repository data aborts before keyring and source installation"
fi
mv "$TMP/nvidia-ctk.mock" "$MOCKBIN/nvidia-ctk"

: >"$CALL_LOG"
if PATH="$MOCKBIN:$PATH" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    MOCK_KEY_FINGERPRINT=0000000000000000000000000000000000000000 \
    "$ROOT/debian/install-tailscale.sh" >/dev/null 2>&1; then
    fail "Tailscale rejects a repository key fingerprint mismatch"
else
    pass "Tailscale rejects a repository key fingerprint mismatch"
fi
if grep -q '/usr/share/keyrings/tailscale-archive-keyring.gpg\|/etc/apt/sources.list.d/tailscale.list' "$CALL_LOG"; then
    fail "Tailscale key mismatch aborts before keyring and source installation"
else
    pass "Tailscale key mismatch aborts before keyring and source installation"
fi

: >"$CALL_LOG"
if PATH="$MOCKBIN:$PATH" SYSTEM_SETUP_TEST_MODE=1 SYSTEM_SETUP_OS_RELEASE="$TMP/os-release" \
    MOCK_KEY_FINGERPRINT=2596A99EAAB33821893C0A79458CA832957F5868 \
    MOCK_REPOSITORY_CONTENT='deb [trusted=yes] https://evil.example/debian bookworm main' \
    "$ROOT/debian/install-tailscale.sh" >/dev/null 2>&1; then
    fail "Tailscale rejects malicious downloaded repository data"
else
    pass "Tailscale rejects malicious downloaded repository data"
fi
if grep -q '/usr/share/keyrings/tailscale-archive-keyring.gpg\|/etc/apt/sources.list.d/tailscale.list' "$CALL_LOG"; then
    fail "malicious Tailscale repository data aborts before keyring and source installation"
else
    pass "malicious Tailscale repository data aborts before keyring and source installation"
fi

SHELL_HOME="$TMP/shell-home"
mkdir "$SHELL_HOME"
cat >"$MOCKBIN/nix" <<'EOF'
#!/bin/sh
printf 'nix %s\n' "$*" >>"$CALL_LOG"
exit 0
EOF
chmod +x "$MOCKBIN/nix"
: >"$CALL_LOG"
SHELL_OUTPUT="$(HOME="$SHELL_HOME" PATH="$MOCKBIN:$PATH" "$ROOT/debian/setup-default-shell.sh" 2>&1)"
assert_failure "default shell rejects missing deployed Nix zsh" test "$?" -eq 0
if grep -q '^nix profile install ' "$CALL_LOG"; then
    fail "default shell never mutates the Nix profile"
else
    pass "default shell never mutates the Nix profile"
fi
if [[ "$SHELL_OUTPUT" == *"Deploy nix-config first so it provides zsh at that path, then rerun the default-shell component."* ]]; then
    pass "missing Nix zsh gives deployment guidance"
else
    fail "missing Nix zsh gives deployment guidance"
fi

assert_failure "no selection rejected" "$ROOT/install.sh" --plan
assert_failure "profile and component rejected" "$ROOT/install.sh" --profile base --component nix --plan
assert_failure "add with component rejected" "$ROOT/install.sh" --component nix --add docker --plan
assert_failure "remove with component rejected" "$ROOT/install.sh" --component nix --remove nix --plan
assert_failure "unknown option rejected" "$ROOT/install.sh" --wat
assert_failure "missing option value rejected" "$ROOT/install.sh" --profile

TERMINAL_TEST="$TMP/terminal-test"
mkdir "$TERMINAL_TEST"
ln -s /usr/bin/bash "$TERMINAL_TEST/bash"
ln -s /usr/bin/readlink "$TERMINAL_TEST/readlink"
ln -s /usr/bin/sh "$TERMINAL_TEST/sh"
make_terminal() {
    local name="$1"
    cat >"$TERMINAL_TEST/$name" <<EOF
#!/bin/sh
printf '%s' '$name' >"$TMP/chosen"
EOF
    chmod +x "$TERMINAL_TEST/$name"
}

make_terminal ghostty
make_terminal x-terminal-emulator
make_terminal i3-sensible-terminal
make_terminal gnome-terminal
PATH="$TERMINAL_TEST" TERMINAL='' "$ROOT/scripts/open-terminal.sh"
assert_eq "terminal fallback prefers Ghostty" "ghostty" "$(<"$TMP/chosen")"
rm "$TERMINAL_TEST/ghostty"
PATH="$TERMINAL_TEST" TERMINAL='' "$ROOT/scripts/open-terminal.sh"
assert_eq "terminal fallback uses x-terminal-emulator" "x-terminal-emulator" "$(<"$TMP/chosen")"
make_terminal preferred-terminal
PATH="$TERMINAL_TEST" TERMINAL=preferred-terminal "$ROOT/scripts/open-terminal.sh"
assert_eq "TERMINAL takes precedence" "preferred-terminal" "$(<"$TMP/chosen")"
PATH="$TERMINAL_TEST" TERMINAL="$ROOT/scripts/open-terminal.sh" "$ROOT/scripts/open-terminal.sh"
assert_eq "terminal helper avoids recursion and falls back" "x-terminal-emulator" "$(<"$TMP/chosen")"

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
((FAIL == 0))
