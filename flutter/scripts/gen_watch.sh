#!/bin/bash

sh scripts/gen_build.sh

declare -a pids

echo "🚀 Starting watch mode..."

find . -name "pubspec.yaml" -not -path "*/build/*" -not -path "*/.dart_tool/*" | while read -r pubspec; do
    module_dir=$(dirname "$pubspec")
    if grep -q "build_runner" "$pubspec" 2>/dev/null; then
        echo "👀 $module_dir"
        (cd "$module_dir" && fvm dart run build_runner watch -d) &
        pids+=($!)
    fi
done

trap "kill ${pids[*]} 2>/dev/null; exit" INT
wait