#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0
FAIL=0

assert() {
    local name="$1"
    shift
    if "$@"; then
        printf 'ok - %s\n' "$name"
        PASS=$((PASS + 1))
    else
        printf 'not ok - %s\n' "$name"
        FAIL=$((FAIL + 1))
    fi
}

# Only allowlisted utilities and local stubs are visible to tested scripts.
mkdir -p "$TMP/bin" "$TMP/home/.nix-profile/bin"
for utility in bash dirname mkdir mktemp chmod cmp rm mv readlink cut cp ln; do
    ln -s "$(command -v "$utility")" "$TMP/bin/$utility"
done
export HOME="$TMP/home" PATH="$TMP/bin" TMPDIR="$TMP"
export CALL_LOG="$TMP/calls" SHELL_STATE="$TMP/passwd-shell"
unset BASH_ENV ENV

# shellcheck source=../lib/nix-config.sh
source "$ROOT/lib/nix-config.sh"
printf ' # managed\n  experimental-features = flakes   nix-command # keep spacing\nkeep-outputs = true' >"$TMP/owner.conf"
cp "$TMP/owner.conf" "$TMP/before.conf"
ln -s owner.conf "$TMP/nix.conf"
assert 'complete symlink config succeeds' ensure_nix_features "$TMP/nix.conf"
assert 'complete config remains a symlink' test -L "$TMP/nix.conf"
assert 'complete symlink destination is preserved' test "$(readlink "$TMP/nix.conf")" = owner.conf
assert 'complete target formatting and final newline remain identical' cmp -s "$TMP/before.conf" "$TMP/owner.conf"

printf 'experimental-features = flakes # nix-command is not enabled\n' >"$TMP/owner.conf"
cp "$TMP/owner.conf" "$TMP/before.conf"
status=0
output="$(ensure_nix_features "$TMP/nix.conf" 2>&1)" || status=$?
assert 'incomplete symlink config fails' test "$status" -ne 0
assert 'incomplete config remains a symlink' test -L "$TMP/nix.conf"
assert 'incomplete symlink destination is preserved' test "$(readlink "$TMP/nix.conf")" = owner.conf
assert 'incomplete target remains identical' cmp -s "$TMP/before.conf" "$TMP/owner.conf"
assert 'failure directs changes to owning configuration' test "${output#*owning configuration}" != "$output"

check_symlink_features() {
    local name="$1" expected="$2" content="$3" status=0
    printf '%s' "$content" >"$TMP/owner.conf"
    cp "$TMP/owner.conf" "$TMP/before.conf"
    ensure_nix_features "$TMP/nix.conf" >"$TMP/output" 2>&1 || status=$?
    assert "$name: effective features" test "$status" -eq "$expected"
    assert "$name: symlink preserved" test -L "$TMP/nix.conf"
    assert "$name: destination preserved" test "$(readlink "$TMP/nix.conf")" = owner.conf
    assert "$name: target bytes preserved" cmp -s "$TMP/before.conf" "$TMP/owner.conf"
}
check_symlink_features 'base assignments do not union' 1 \
    $'experimental-features = nix-command\nexperimental-features = flakes\n'
check_symlink_features 'later base removes a required feature' 1 \
    $'experimental-features = nix-command flakes\nexperimental-features = nix-command\n'
check_symlink_features 'last complete base wins' 0 \
    $'experimental-features = flakes\nexperimental-features = nix-command flakes\n'
check_symlink_features 'empty base clears earlier features' 1 \
    $'experimental-features = nix-command flakes\nexperimental-features = # reset\n'
check_symlink_features 'extra assignment extends base' 0 \
    $'experimental-features = nix-command\n  extra-experimental-features = flakes # additive\n'
check_symlink_features 'extra-only assignment enables both features' 0 \
    $'extra-experimental-features = flakes nix-command\n'
check_symlink_features 'repeated extras accumulate' 0 \
    $'extra-experimental-features = nix-command\nextra-experimental-features = flakes\n'
check_symlink_features 'later base discards earlier extras' 1 \
    $'extra-experimental-features = nix-command flakes\nexperimental-features = flakes\n'
check_symlink_features 'extra after replacement restores feature' 0 \
    $'experimental-features = nix-command flakes\nexperimental-features = flakes\nextra-experimental-features = nix-command\n'
check_symlink_features 'empty extra preserves earlier features' 0 \
    $'experimental-features = nix-command flakes\nextra-experimental-features = # no additions\n'
check_symlink_features 'commented extra feature is not enabled' 1 \
    $'experimental-features = nix-command\nextra-experimental-features = # flakes\n'

ln -s missing.conf "$TMP/broken.conf"
status=0
ensure_nix_features "$TMP/broken.conf" >"$TMP/output" 2>&1 || status=$?
assert 'dangling symlink config fails' test "$status" -ne 0
assert 'dangling symlink is preserved' test -L "$TMP/broken.conf"
assert 'dangling target is not created' test ! -e "$TMP/missing.conf"
printf 'experimental-features = flakes\n' >"$TMP/regular.conf"
assert 'regular config still receives missing feature' ensure_nix_features "$TMP/regular.conf"
assert 'regular config retains flakes and adds nix-command' test "$(<"$TMP/regular.conf")" = 'experimental-features = flakes nix-command'

# This stub detects the recursive dispatch condition without actually recursing.
# Variables expand when the generated stub runs.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' \
    '[[ ! -v TERMINAL ]] || exit 91' \
    'printf "%s\n" "$@" >"$CALL_LOG"' >"$TMP/bin/i3-sensible-terminal"
chmod +x "$TMP/bin/i3-sensible-terminal"
ln -s "$ROOT/scripts/open-terminal.sh" "$TMP/bin/open-terminal"
: >"$CALL_LOG"
run_terminal() {
    local selected="$1"
    shift
    TERMINAL="$selected" bash "$ROOT/scripts/open-terminal.sh" "$@"
}
assert 'helper-valued TERMINAL is cleared for i3 fallback' run_terminal open-terminal --title 'two words'
assert 'terminal argument boundaries are preserved' test "$(<"$CALL_LOG")" = $'--title\ntwo words'
assert 'explicit i3-sensible-terminal does not inherit itself' run_terminal i3-sensible-terminal
cp "$TMP/bin/i3-sensible-terminal" "$TMP/bin/preferred-terminal"
assert 'explicit preferred terminal receives no TERMINAL' run_terminal preferred-terminal preferred
assert 'explicit terminal takes precedence' test "$(<"$CALL_LOG")" = preferred
: >"$CALL_LOG"
assert 'terminal check succeeds without execution' run_terminal open-terminal --check
assert 'terminal check does not execute stub' test ! -s "$CALL_LOG"

# All account and privilege commands are mocked; no host passwd or shells access.
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' >"$HOME/.nix-profile/bin/zsh"
chmod +x "$HOME/.nix-profile/bin/zsh"
# Variables expand when the generated stub runs.
# shellcheck disable=SC2016
printf '%s\n' '#!/usr/bin/env bash' \
    'case "${0##*/}" in' \
    'id) [[ "${MOCK_LOOKUP:-}" != id-fail ]] || exit 2; printf "fixture\n" ;;' \
    'getent)' \
    '  [[ "$*" == "passwd fixture" ]] || exit 98' \
    '  case "${MOCK_LOOKUP:-}" in' \
    '    fail) exit 2 ;;' \
    '    empty) exit 0 ;;' \
    '    malformed) printf "invalid\n"; exit 0 ;;' \
    '    post-fail) [[ ! -s "$CALL_LOG" ]] || exit 2 ;;' \
    '  esac' \
    '  printf "fixture:x:1000:1000::%s:%s\n" "$HOME" "$(<"$SHELL_STATE")" ;;' \
    'grep) [[ "$*" == "-Fxq $HOME/.nix-profile/bin/zsh /etc/shells" ]] || exit 98 ;;' \
    'sudo) printf "unexpected sudo\n" >>"$CALL_LOG"; exit 99 ;;' \
    'chsh)' \
    '  printf "chsh %s\n" "$*" >>"$CALL_LOG"' \
    '  [[ "$1" == -s && "$2" == "$HOME/.nix-profile/bin/zsh" ]] || exit 98' \
    '  [[ "${MOCK_LOOKUP:-}" == unchanged ]] || printf "%s\n" "$2" >"$SHELL_STATE" ;;' \
    'esac' >"$TMP/account-stub"
chmod +x "$TMP/account-stub"
for utility in id getent grep sudo chsh; do
    ln -s "$TMP/account-stub" "$TMP/bin/$utility"
done

run_shell() {
    SHELL="$1" MOCK_LOOKUP="${2:-}" SYSTEM_SETUP_YES=1 \
        bash "$ROOT/debian/setup-default-shell.sh" >"$TMP/output" 2>&1
}
printf '/bin/bash\n' >"$SHELL_STATE"
: >"$CALL_LOG"
assert 'stale SHELL cannot suppress necessary passwd shell change' run_shell "$HOME/.nix-profile/bin/zsh"
assert 'chsh is called with deployed zsh' test "$(<"$CALL_LOG")" = "chsh -s $HOME/.nix-profile/bin/zsh"
: >"$CALL_LOG"
assert 'correct passwd shell succeeds despite stale SHELL' run_shell /bin/bash
assert 'correct passwd shell skips chsh' test ! -s "$CALL_LOG"

for mode in fail empty malformed id-fail; do
    : >"$CALL_LOG"
    status=0
    run_shell "$HOME/.nix-profile/bin/zsh" "$mode" || status=$?
    assert "passwd lookup $mode fails safely" test "$status" -ne 0
    assert "passwd lookup $mode causes no mutation" test ! -s "$CALL_LOG"
    output="$(<"$TMP/output")"
    assert "passwd lookup $mode provides a diagnostic" test "${output#*Unable to look up}" != "$output"
done
for mode in post-fail unchanged; do
    printf '/bin/bash\n' >"$SHELL_STATE"
    : >"$CALL_LOG"
    status=0
    run_shell /bin/bash "$mode" || status=$?
    assert "post-change verification $mode is reported as failure" test "$status" -ne 0
    assert "post-change verification $mode follows chsh" test "$(<"$CALL_LOG")" = "chsh -s $HOME/.nix-profile/bin/zsh"
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
((FAIL == 0))
