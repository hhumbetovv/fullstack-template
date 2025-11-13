#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

if set -o | grep -Eq '^posix[[:space:]]+on$'; then
  exec bash "$0" "$@"
fi

set +e

warn() {
  printf 'Warning: %s\n' "$1"
}

run_step() {
  "$@"
  local status=$?
  if [ $status -ne 0 ]; then
    warn "Command '$*' failed with exit code $status; continuing."
  fi
}

get_flutter_version() {
  if [ ! -f .fvmrc ]; then
    return 0
  fi

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq is not installed; skipping fvm global update."
    return 1
  fi

  local version="$(jq -r '.flutter // empty' .fvmrc 2>/dev/null)"
  if [ -z "$version" ]; then
    warn "Unable to parse Flutter version from .fvmrc; skipping fvm global update."
    return 1
  fi

  printf '%s' "$version"
}

ensure_fvm_bin_on_path() {
  local version="$1"
  if [ -z "$version" ]; then
    warn "Flutter version is empty; skipping PATH export."
    return 1
  fi

  local rel_bin_dir=".fvm/versions/$version/bin"
  if [ ! -d "$rel_bin_dir" ]; then
    warn "Expected Flutter SDK directory '$rel_bin_dir' not found; run 'fvm use'."
    return 1
  fi

  local abs_bin_dir
  abs_bin_dir="$(cd "$rel_bin_dir" 2>/dev/null && pwd)"
  if [ -z "$abs_bin_dir" ]; then
    warn "Unable to resolve absolute path for '$rel_bin_dir'."
    return 1
  fi

  case ":$PATH:" in
    *":$abs_bin_dir:"*) ;;
    *) export PATH="$abs_bin_dir:$PATH" ;;
  esac
}

run_step bash scripts/bash/setup.sh
run_step fvm use

flutter_version="$(get_flutter_version)"
if [ -n "$flutter_version" ] && [ "$flutter_version" != "null" ]; then
  run_step fvm global "$flutter_version"
  ensure_fvm_bin_on_path "$flutter_version"
else
  warn "Unable to determine Flutter version from .fvmrc; skipping fvm global update."
fi

run_step fvm flutter clean

if pushd app >/dev/null 2>&1; then
  run_step fvm flutter clean
  run_step fvm flutter pub get
  run_step fvm flutter precache --ios

  if pushd ios >/dev/null 2>&1; then
    if command -v pod >/dev/null 2>&1; then
      run_step pod deintegrate
      run_step pod repo update
      run_step pod install
    else
      warn "CocoaPods (pod) command not found; skipping iOS pod steps."
    fi
    popd >/dev/null 2>&1 || true
  else
    warn "Unable to enter app/ios directory; skipping CocoaPods steps."
  fi

  popd >/dev/null 2>&1 || true
else
  warn "Unable to enter app directory; skipping Flutter app preparation."
fi

run_step fvm flutter pub get

run_step fvm dart pub global activate flutterfire_cli
if ! command -v flutterfire >/dev/null 2>&1; then
  warn "flutterfire_cli (flutterfire) command not available; ensure pub-cache/bin is in PATH."
fi

run_step fvm dart pub global activate icon_font_generator
if ! command -v icon_font_generator >/dev/null 2>&1; then
  warn "icon_font_generator command not available; ensure pub-cache/bin is in PATH."
fi

run_step fvm dart run scripts smart-build
