#!/usr/bin/env bash

if [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

if set -o | grep -Eq '^posix[[:space:]]+on$'; then
  exec bash "$0" "$@"
fi

set +e

warn() {
  printf 'Warning: %s\n' "$1" >&2
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

  if command -v jq >/dev/null 2>&1; then
    local version
    version="$(jq -r '.flutter // .version // empty' .fvmrc 2>/dev/null)"
    if [ -n "$version" ] && [ "$version" != "null" ]; then
      printf '%s' "$version"
      return 0
    fi
  fi

  local version=""
  version=$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc | head -n1)
  if [ -z "$version" ]; then
    version=$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc | head -n1)
  fi

  if [ -n "$version" ]; then
    printf '%s' "$version"
    return 0
  fi

  warn "Unable to parse Flutter version from .fvmrc without jq; continuing without global update."
  return 1
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

is_windows() {
  case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
    *mingw*|*msys*|*cygwin*) return 0 ;;
  esac
  if [ "${OS:-}" = "Windows_NT" ]; then
    return 0
  fi
  return 1
}

try_fvm_use_with_elevation() {
  fvm use
  local status=$?
  if [ $status -eq 0 ]; then
    return 0
  fi
  if is_windows; then
    local fvm_bat=""
    if [ -n "$LOCALAPPDATA" ] && [ -f "$LOCALAPPDATA/Pub/Cache/bin/fvm.bat" ]; then
      fvm_bat="$LOCALAPPDATA/Pub/Cache/bin/fvm.bat"
    elif [ -n "$APPDATA" ] && [ -f "$APPDATA/Pub/Cache/bin/fvm.bat" ]; then
      fvm_bat="$APPDATA/Pub/Cache/bin/fvm.bat"
    fi

    if [ -n "$fvm_bat" ]; then
      powershell.exe -NoProfile -Command "Start-Process -Verb RunAs -FilePath '$fvm_bat' -ArgumentList 'use' -Wait"
      return $?
    else
      warn "Unable to locate fvm.bat for elevation; ensure FVM is installed or adjust PATH."
    fi
  fi
  return $status
}

ensure_pub_cache_bin_on_path() {
  local candidates=()
  if [ -n "$PUB_CACHE" ]; then candidates+=("$PUB_CACHE/bin"); fi
  if [ -n "$HOME" ]; then candidates+=("$HOME/.pub-cache/bin"); fi
  if [ -n "$LOCALAPPDATA" ]; then candidates+=("$LOCALAPPDATA/Pub/Cache/bin"); fi
  if [ -n "$APPDATA" ]; then candidates+=("$APPDATA/Pub/Cache/bin"); fi

  for dir in "${candidates[@]}"; do
    if [ -d "$dir" ]; then
      case ":$PATH:" in
        *":$dir:"*) ;;
        *) export PATH="$dir:$PATH" ;;
      esac
    fi
  done
}

resolve_pod_command() {
  if [ -n "${POD_COMMAND:-}" ] && [ -x "$POD_COMMAND" ]; then
    printf '%s' "$POD_COMMAND"
    return 0
  fi

  local rbenv_pod="$HOME/.rbenv/shims/pod"
  if [ -x "$rbenv_pod" ]; then
    POD_COMMAND="$rbenv_pod"
    printf '%s' "$POD_COMMAND"
    return 0
  fi

  if command -v pod >/dev/null 2>&1; then
    POD_COMMAND="$(command -v pod)"
    printf '%s' "$POD_COMMAND"
    return 0
  fi

  return 1
}

has_ios_artifacts() {
  local version="$1"
  if [ -z "$version" ]; then
    return 1
  fi

  local framework_dir=".fvm/versions/$version/bin/cache/artifacts/engine/ios/Flutter.xcframework"
  if [ -d "$framework_dir" ]; then
    return 0
  fi

  return 1
}

run_step bash scripts/bash/setup.sh
ensure_pub_cache_bin_on_path
try_fvm_use_with_elevation || warn "'fvm use' did not complete; continuing."

flutter_version="$(get_flutter_version)"
if [ -n "$flutter_version" ] && [ "$flutter_version" != "null" ]; then
  run_step fvm global "$flutter_version"
  if ! is_windows; then
    ensure_fvm_bin_on_path "$flutter_version"
  fi
else
  warn "Unable to determine Flutter version from .fvmrc; skipping fvm global update."
fi

run_step fvm flutter clean

if pushd app >/dev/null 2>&1; then
  run_step fvm flutter clean
  run_step fvm flutter pub get
  skip_ios_bootstrap=0
  if [ -n "${SKIP_IOS_BOOTSTRAP:-}" ]; then
    skip_ios_bootstrap=1
    warn "SKIP_IOS_BOOTSTRAP is set; skipping Flutter iOS precache and CocoaPods steps."
  fi

  if [ $skip_ios_bootstrap -eq 0 ]; then
    if has_ios_artifacts "$flutter_version"; then
      printf 'iOS Flutter artifacts already present; skipping precache.\n'
    else
      run_step fvm flutter precache --ios
    fi

    if pushd ios >/dev/null 2>&1; then
      pod_cmd=""
      if pod_cmd=$(resolve_pod_command); then
        run_step "$pod_cmd" deintegrate
        run_step "$pod_cmd" repo update
        run_step "$pod_cmd" install
      else
        warn "CocoaPods (pod) command not found; skipping iOS pod steps."
      fi
      popd >/dev/null 2>&1 || true
    else
      warn "Unable to enter app/ios directory; skipping CocoaPods steps."
    fi
  else
    printf 'Skipping Flutter iOS precache and CocoaPods steps; SKIP_IOS_BOOTSTRAP is set.\n'
  fi

  popd >/dev/null 2>&1 || true
else
  warn "Unable to enter app directory; skipping Flutter app preparation."
fi

run_step fvm flutter pub get

run_step fvm dart pub global activate flutterfire_cli
ensure_pub_cache_bin_on_path
if ! command -v flutterfire >/dev/null 2>&1; then
  warn "flutterfire_cli (flutterfire) command not available; ensure pub-cache/bin is in PATH."
fi

run_step fvm dart pub global activate icon_font_generator
ensure_pub_cache_bin_on_path
if ! command -v icon_font_generator >/dev/null 2>&1; then
  warn "icon_font_generator command not available; ensure pub-cache/bin is in PATH."
fi

run_step fvm dart run scripts smart-build
