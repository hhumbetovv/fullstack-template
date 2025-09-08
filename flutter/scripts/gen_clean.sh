#!/bin/bash

echo "🚀 Cleaning generated files\n"

declare -a pids

for pubspec in $(find . -name "pubspec.yaml" -not -path "*/build/*" -not -path "*/.dart_tool/*"); do
    module_dir=$(dirname "$pubspec")
    if grep -q "build_runner" "$pubspec" 2>/dev/null; then
        echo "🧹 $module_dir"
        (cd "$module_dir" && fvm dart run build_runner clean) &
        pids+=($!)
    fi
done

echo "\n⏳ Waiting for cleanup processes...\n"
for pid in "${pids[@]}"; do
    wait $pid
done

echo "\n🧹 Cleaning build artifacts to prevent conflicts..."
find . -name "*.g.dart" -o -name "*.freezed.dart" -o -name "*.gr.dart" -o -name "*.config.dart" -o -name "public.dart" | xargs rm -f 2>/dev/null
rm -rf .dart_tool/build
echo "\n✅ All cleanups completed\n"