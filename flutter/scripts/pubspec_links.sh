#!/bin/bash

# Pubspec Symlinks Creator
# This script finds all pubspec.yaml files in the project and creates symlinks in the pubspecs folder

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Banner
printf "${BLUE}=====================================${NC}\n"
printf "${BLUE}    Pubspec Symlinks Creator${NC}\n"
printf "${BLUE}=====================================${NC}\n"

# Create pubspecs directory
PUBSPECS_DIR="yaml/pubspecs"

if [ -d "$PUBSPECS_DIR" ]; then
    printf "${YELLOW}Warning: $PUBSPECS_DIR directory already exists. Cleaning contents...${NC}\n"
    rm -rf "$PUBSPECS_DIR"/*
else
    printf "${GREEN}Creating $PUBSPECS_DIR directory...${NC}\n"
fi

mkdir -p "$PUBSPECS_DIR"

# Counters
count=0
skipped=0

printf "\n${BLUE}Searching for pubspec.yaml files...${NC}\n"

# Find all pubspec.yaml files (exclude node_modules, .git, build directories)
find . -name "pubspec.yaml" \
    -not -path "./.git/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/build/*" \
    -not -path "*/.dart_tool/*" \
    -not -path "*/ios/Flutter/*" \
    -not -path "*/android/.gradle/*" \
    -not -path "*/.fvm/*" | while read pubspec_file; do
    
    # Skip if file doesn't exist (safety check)
    if [ ! -f "$pubspec_file" ]; then
        continue
    fi
    
    # Get directory path and normalize it
    dir_path=$(dirname "$pubspec_file")
    
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
    while [ -e "$PUBSPECS_DIR/${link_name}.yaml" ]; do
        link_name="${original_link_name}_${counter}"
        counter=$((counter + 1))
    done
    
    # Symlink file name
    symlink_file="$PUBSPECS_DIR/${link_name}.yaml"
    
    # Get absolute path
    if command -v realpath > /dev/null 2>&1; then
        abs_pubspec_path=$(realpath "$pubspec_file")
    else
        # Fallback for systems without realpath
        abs_pubspec_path=$(cd "$(dirname "$pubspec_file")" && pwd)/$(basename "$pubspec_file")
    fi
    
    # Create symlink
    if ln -sf "$abs_pubspec_path" "$symlink_file" 2>/dev/null; then
        printf "${GREEN}✓${NC} $pubspec_file -> $(basename "$symlink_file")\n"
        count=$((count + 1))
    else
        printf "${RED}✗${NC} Failed to create symlink: $pubspec_file\n"
        skipped=$((skipped + 1))
    fi
done

# Wait for background processes to complete
wait

# Count actual symlinks created
actual_count=$(find "$PUBSPECS_DIR" -name "*.yaml" 2>/dev/null | wc -l | tr -d ' ')

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