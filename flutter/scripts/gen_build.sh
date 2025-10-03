#!/bin/bash

set -euo pipefail

# Discover modules (pubspec.yaml) and map names to directories.
declare -A MODULE_PATHS=()
declare -A PATH_NAMES=()

while IFS= read -r pubspec; do
  module_dir=$(dirname "$pubspec")
  module_name=$(grep -E "^name:" "$pubspec" | awk '{print $2}')

  if [[ -n "$module_name" ]]; then
    MODULE_PATHS["$module_name"]="$module_dir"
    PATH_NAMES["$module_dir"]="$module_name"
  fi
done < <(find . -name "pubspec.yaml" -not -path "*/build/*" -not -path "*/.dart_tool/*")

if [[ ${#MODULE_PATHS[@]} -eq 0 ]]; then
  echo "❌ No modules discovered. Are you in the repository root?"
  exit 1
fi

build_module() {
  local module_path=$1
  local module_name=${PATH_NAMES["$module_path"]:-$(basename "$module_path")}

  if [[ ! -f "$module_path/pubspec.yaml" ]]; then
    echo "❌ pubspec.yaml not found in $module_path, skipping...\n"
    return
  fi

  if ! grep -q "build_runner" "$module_path/pubspec.yaml" 2>/dev/null; then
    echo "⚠️  No build_runner found in $module_name ($module_path), skipping...\n"
    return
  fi

  echo "🔨 Building $module_name ($module_path)...\n"
  (cd "$module_path" && dart run build_runner build -d)
  echo "\n✅ Build complete for $module_name\n"
}

resolve_target() {
  local target=$1

  if [[ -n ${MODULE_PATHS["$target"]:-} ]]; then
    echo "${MODULE_PATHS["$target"]}"
    return 0
  fi

  if [[ -d "$target" && -f "$target/pubspec.yaml" ]]; then
    echo "$target"
    return 0
  fi

  if [[ -d "./$target" && -f "./$target/pubspec.yaml" ]]; then
    echo "./$target"
    return 0
  fi

  return 1
}

if [[ $# -gt 0 ]]; then
  echo "\n🎯 Building specific module(s): $*\n"
  for target in "$@"; do
    if module_path=$(resolve_target "$target"); then
      build_module "$module_path"
    else
      echo "⚠️  Module '$target' not found by name or path, skipping...\n"
    fi
  done
else
  echo "\n🔍 Building all discovered modules...\n"
  mapfile -t ALL_MODULES < <(printf '%s\n' "${!MODULE_PATHS[@]}" | sort)
  for module_name in "${ALL_MODULES[@]}"; do
    module_path=${MODULE_PATHS["$module_name"]}
    build_module "$module_path"
  done
fi

echo "\n🎉 Build process completed!\n"
