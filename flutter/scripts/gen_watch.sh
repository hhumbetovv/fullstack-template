#!/bin/bash

PRE_BUILD=false
declare -a MODULE_NAMES=()

for arg in "$@"; do
  if [ "$arg" == "--pre-build" ]; then
    PRE_BUILD=true
  else
    MODULE_NAMES+=("$arg")
  fi
done

if [ "$PRE_BUILD" = true ]; then
  dart scripts/smart_build.dart
fi

declare -a pids

echo "🚀 Starting watch mode..."

find . -name "pubspec.yaml" -not -path "*/build/*" -not -path "*/.dart_tool/*" | while read -r pubspec; do
    module_dir=$(dirname "$pubspec")
    name=$(grep -E "^name:" "$pubspec" | awk '{print $2}')

    if [ ${#MODULE_NAMES[@]} -gt 0 ]; then
        skip=true
        for m in "${MODULE_NAMES[@]}"; do
            if [ "$name" == "$m" ]; then
                skip=false
                break
            fi
        done
        if [ "$skip" = true ]; then
            continue
        fi
    fi

    if grep -q "build_runner" "$pubspec" 2>/dev/null; then
        echo "👀 $module_dir ($name)"
        (cd "$module_dir" && fvm dart run build_runner watch -d) &
        pids+=($!)
    fi
done

trap "kill ${pids[*]} 2>/dev/null; exit" INT
wait