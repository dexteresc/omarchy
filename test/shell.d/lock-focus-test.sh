#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_root=$(mktemp -d)
runtime_root=$(mktemp -d)

cleanup() {
  rm -rf -- "$test_root" "$runtime_root"
}
trap cleanup EXIT

chmod 700 "$runtime_root"
cp "$SHELL_TEST_DIR/fixtures/lock-focus/shell.qml" "$test_root/shell.qml"
ln -s "$ROOT/shell/plugins/lock" "$test_root/LockPlugin"
ln -s "$ROOT/shell/Ui" "$test_root/Ui"
ln -s "$ROOT/shell/Commons" "$test_root/Commons"
mkdir -p "$test_root/home"

output=$(
  HOME="$test_root/home" \
    XDG_RUNTIME_DIR="$runtime_root" \
    QT_QPA_PLATFORM=offscreen \
    QT_QUICK_BACKEND=software \
    QT_QPA_PLATFORMTHEME= \
    DISPLAY= \
    WAYLAND_DISPLAY= \
    OMARCHY_PATH="$ROOT" \
    timeout 10s quickshell -p "$test_root" --no-color 2>&1
) || fail "lock focus fixture exits cleanly" "$output"

rg -q "LOCK_FOCUS_TEST_PASS" <<<"$output" ||
  fail "lock password input reclaims focus without a pointer click" "$output"

pass "lock password input reclaims focus without a pointer click"
