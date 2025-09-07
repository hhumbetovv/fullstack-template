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
    
    # Get file path
    dir_path=$(dirname "$pubspec_file")
    dir_name=$(basename "$dir_path")
    
    # If directory with same name exists, add parent directory name
    link_name="$dir_name"
    parent_dir=$(basename "$(dirname "$dir_path")")
    
    # Check for root pubspec
    if [ "$dir_path" = "." ]; then
        link_name="root"
    # If same name link exists, add parent directory name
    elif [ -e "$PUBSPECS_DIR/${link_name}_pubspec.yaml" ]; then
        link_name="${parent_dir}_${dir_name}"
    fi
    
    # Symlink file name
    symlink_file="$PUBSPECS_DIR/${link_name}_pubspec.yaml"
    
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
actual_count=$(find "$PUBSPECS_DIR" -name "*_pubspec.yaml" 2>/dev/null | wc -l | tr -d ' ')

# Result summary
printf "\n${BLUE}=====================================${NC}\n"
printf "${GREEN}✓ Total symlinks created: $actual_count${NC}\n"
if [ "$skipped" -gt 0 ]; then
    printf "${RED}✗ Failed: $skipped${NC}\n"
fi
printf "${BLUE}=====================================${NC}\n"

printf "• You can re-run this script after any changes\n"

printf "\n${GREEN}Script completed successfully!${NC}\n"