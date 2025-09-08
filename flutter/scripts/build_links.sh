#!/bin/bash

# Build Symlinks Creator
# This script finds all build.yaml files in the project and creates symlinks in the builds folder

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
printf "${BLUE}=====================================${NC}\n"
printf "${BLUE}    Build Symlinks Creator${NC}\n"
printf "${BLUE}=====================================${NC}\n"

# Create builds directory
BUILDS_DIR="yaml/builds"

if [ -d "$BUILDS_DIR" ]; then
    printf "${YELLOW}Warning: $BUILDS_DIR directory already exists. Cleaning contents...${NC}\n"
    rm -rf "$BUILDS_DIR"/*
else
    printf "${GREEN}Creating $BUILDS_DIR directory...${NC}\n"
fi

mkdir -p "$BUILDS_DIR"

# Counters
count=0
skipped=0

printf "\n${BLUE}Searching for build.yaml files...${NC}\n"

# Find all build.yaml files (exclude node_modules, .git, build directories)
find . -name "build.yaml" \
    -not -path "./.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/build/*" \
    -not -path "*/.dart_tool/*" \
    -not -path "*/ios/Flutter/*" \
    -not -path "*/android/.gradle/*" \
    -not -path "*/.fvm/*" | while read build_file; do
    
    # Skip if file doesn't exist (safety check)
    if [ ! -f "$build_file" ]; then
        continue
    fi
    
    # Get directory path and normalize it
    dir_path=$(dirname "$build_file")
    
    # Create link name based on full path
    if [ "$dir_path" = "." ]; then
        link_name="root"
    else
        # Remove leading './' and convert path separators to underscores
        # Also handle cases where path starts without './'
        link_name=$(echo "$dir_path" | sed 's|^./||' | sed 's|^/||' | tr '/' '_')
        
        # If link_name is empty (shouldn't happen but safety check)
        if [ -z "$link_name" ]; then
            link_name=$(basename "$dir_path")
        fi
    fi
    
    # Ensure unique naming in case of conflicts
    original_link_name="$link_name"
    counter=1
    while [ -e "$BUILDS_DIR/${link_name}.yaml" ]; do
        link_name="${original_link_name}_${counter}"
        counter=$((counter + 1))
    done
    
    # Symlink file name
    symlink_file="$BUILDS_DIR/${link_name}.yaml"
    
    # Get absolute path
    if command -v realpath > /dev/null 2>&1; then
        abs_build_path=$(realpath "$build_file")
    else
        # Fallback for systems without realpath
        abs_build_path=$(cd "$(dirname "$build_file")" && pwd)/$(basename "$build_file")
    fi
    
    # Create symlink
    if ln -sf "$abs_build_path" "$symlink_file" 2>/dev/null; then
        printf "${GREEN}✓${NC} $build_file -> $(basename "$symlink_file")\n"
        count=$((count + 1))
    else
        printf "${RED}✗${NC} Failed to create symlink: $build_file\n"
        skipped=$((skipped + 1))
    fi
done

# Wait for background processes to complete
wait

# Count actual symlinks created
actual_count=$(find "$BUILDS_DIR" -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')

# Result summary
printf "\n${BLUE}=====================================${NC}\n"
printf "${GREEN}✓ Total symlinks created: $actual_count${NC}\n"
if [ "$skipped" -gt 0 ]; then
    printf "${RED}✗ Failed: $skipped${NC}\n"
fi
printf "${BLUE}=====================================${NC}\n"

printf "• You can re-run this script after any changes\n"
printf "• Path structure is preserved in symlink names\n"

printf "\n${GREEN}Script completed successfully!${NC}\n"