#!/bin/bash
# Regression test: top-level plan mode must not write, sudo, or touch the network.
#
# Covers the --plan forwarding bug: `./install.sh flatpak --plan` used to drop
# `--plan` when dispatching to debian/install-flatpak.sh, so a dry run could
# perform sudo/network writes. The test runs the top-level dispatcher with an
# isolated HOME and a stubbed PATH (fake sudo fails if called, fake flatpak
# records calls) and asserts exit 0, zero stub invocations, plan-only output,
# and no files created under the temp HOME.
#
# Run: ./tests/test-plan-forwarding.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

FAKE_HOME="${TMP}/home"
STUB_BIN="${TMP}/bin"
CALLS_LOG="${TMP}/calls.log"
mkdir -p "${FAKE_HOME}" "${STUB_BIN}"
: > "${CALLS_LOG}"

# Fake sudo: record and fail — plan mode must never reach it.
cat > "${STUB_BIN}/sudo" <<'EOF'
#!/bin/bash
echo "sudo $*" >> "${PLAN_TEST_CALLS_LOG:?}"
echo "FAIL: sudo invoked during --plan: $*" >&2
exit 1
EOF
chmod +x "${STUB_BIN}/sudo"

# Fake flatpak: record calls — plan mode must never reach it either.
cat > "${STUB_BIN}/flatpak" <<'EOF'
#!/bin/bash
echo "flatpak $*" >> "${PLAN_TEST_CALLS_LOG:?}"
exit 0
EOF
chmod +x "${STUB_BIN}/flatpak"

export PLAN_TEST_CALLS_LOG="${CALLS_LOG}"

echo "[*] Running: ./install.sh flatpak --plan (isolated HOME, stubbed PATH)"
output="$(HOME="${FAKE_HOME}" PATH="${STUB_BIN}:${PATH}" bash "${REPO_ROOT}/install.sh" flatpak --plan 2>&1)"
status=$?
echo "${output}"

fail() {
  echo "[FAIL] $1" >&2
  exit 1
}

[[ "${status}" -eq 0 ]] || fail "expected exit 0, got ${status}"
echo "${output}" | grep -q '\[PLAN\]' || fail "expected plan-only output ([PLAN]), got none"
[[ ! -s "${CALLS_LOG}" ]] || fail "stub invoked during --plan: $(cat "${CALLS_LOG}")"
[[ -z "$(ls -A "${FAKE_HOME}")" ]] || fail "files created under temp HOME: $(ls -A "${FAKE_HOME}")"

echo "[OK] plan mode performs no writes/sudo/network"
