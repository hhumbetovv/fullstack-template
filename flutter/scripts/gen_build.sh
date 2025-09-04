#!/bin/bash

MODULES_ORDER=(
    "./processor"
    "./common/shared" 
    "./common/presentation" 
    "./core/domain" 
    "./core/data" 
    "./core/presentation" 
    "./data" 
    "./domain" 
    "./core" 
    "./uikit" 
    "./app"
)

declare -a pids

echo "\n🔍 Running initial build on all modules to ensure proper file generation...\n"

for module_dir in "${MODULES_ORDER[@]}"; do
  if [ -f "$module_dir/pubspec.yaml" ]; then
    if grep -q "build_runner" "$module_dir/pubspec.yaml"; then
      echo "🔨 Building $module_dir...\n"
      (cd "$module_dir" && fvm dart run build_runner build -d)
      echo "\n✅ Build complete for $module_dir\n"
    fi
  fi
done
