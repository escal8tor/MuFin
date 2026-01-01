#!/bin/bash
# shellcheck shell=bash

# Original author: saitamasahil

set -e

# Get project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create build directory if it doesn't exist
BUILD_DIR="$PROJECT_ROOT/build"
if [ ! -d "$BUILD_DIR" ]; then
    echo "Creating build directory: $BUILD_DIR"
    mkdir -p "$BUILD_DIR"
fi

# Read version from globals.lua
MAJOR=$(grep -oP 'major = \K\d+' "$PROJECT_ROOT/app/src/helpers/globals.lua")
MINOR=$(grep -oP 'minor = \K\d+' "$PROJECT_ROOT/app/src/helpers/globals.lua")
PATCH=$(grep -oP 'patch = \K\d+' "$PROJECT_ROOT/app/src/helpers/globals.lua")

if [ -z "$MAJOR" ] || [ -z "$MINOR" ] || [ -z "$PATCH" ]; then
    echo "Error: Could not determine version from globals.lua"
    exit 1
fi

TAG="v${MAJOR}.${MINOR}.${PATCH}"
echo "Building version: $TAG"

# Set up paths
FULL="$BUILD_DIR/MuFin_${TAG}.muxapp"
UPDATE="$BUILD_DIR/MuFin_${TAG}_update.muxapp"
WORKDIR="$BUILD_DIR/pkg_${MAJOR}${MINOR}${PATCH}"

# Clean up old build
rm -rf "$WORKDIR" "$FULL" "$UPDATE"
mkdir -p "$WORKDIR/MuFin/app"

# Copy all necessary files
echo "Copying files..."
cp "$PROJECT_ROOT/mux_launch.sh" "$WORKDIR/MuFin/"

# Copy core directories
cp -r "$PROJECT_ROOT/app/src"      "$WORKDIR/MuFin/app/src"
cp -r "$PROJECT_ROOT/app/res"      "$WORKDIR/MuFin/app/res"
cp -r "$PROJECT_ROOT/app/data"     "$WORKDIR/MuFin/app/data"
cp -r "$PROJECT_ROOT/app/conf.lua" "$WORKDIR/MuFin/app/conf.lua"
cp -r "$PROJECT_ROOT/app/main.lua" "$WORKDIR/MuFin/app/main.lua"

# Ensure glyph directory exists in the root of the app and copy scrappy.png
mkdir -p "$WORKDIR/MuFin/glyph"
GLYPH_SRC=""

if [ -f "$PROJECT_ROOT/glyph/mufin.png" ]; then
    GLYPH_SRC="$PROJECT_ROOT/glyph/mufin.png"
fi

if [ -n "$GLYPH_SRC" ]; then
    echo "Copying scrappy.png to glyph directory..."
    cp "$GLYPH_SRC" "$WORKDIR/MuFin/glyph/"

    # Convert per-resolution icons into their respective folders.
    for res in 640x480:21x21 720x480:21x21 720x720:36x36 1024x768:36x36; do 
        IFS=: read -r res size <<< $res
        mkdir -p "$WORKDIR/MuFin/glyph/$res"
        convert -resize $size "$GLYPH_SRC" "$WORKDIR/MuFin/glyph/$res/mufin.png"
    done
else
    echo "Warning: mufin.png not found in expected locations"
fi

# Create update package
echo "Creating update package..."
(cd "$WORKDIR" && zip -qr "$UPDATE" ./MuFin)


cp -r "$PROJECT_ROOT/app/bin" "$WORKDIR/MuFin/app/bin"

# Create full package
echo "Creating full package..."
(cd "$WORKDIR" && zip -qr "$FULL" ./MuFin)

# Clean up
rm -rf "$WORKDIR"

echo -e "\nBuild complete! Created:"
ls -lh "$FULL"
ls -lh "$UPDATE"