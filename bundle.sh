#!/bin/bash
set -euo pipefail

APP_NAME="MacBarMonitor"
BUILD_DIR="MacBarMonitor.app"
RELEASE_BINARY=".build/release/MacBarMonitor"

echo "Building release binary..."
swift build -c release

if [ ! -f "$RELEASE_BINARY" ]; then
    echo "Error: Release binary not found at $RELEASE_BINARY"
    exit 1
fi

echo "Creating app bundle structure..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/Contents/Resources"

echo "Copying binary..."
cp "$RELEASE_BINARY" "$BUILD_DIR/Contents/MacOS/$APP_NAME"

echo "Copying Info.plist..."
cp "Sources/MacBarMonitor/Info.plist" "$BUILD_DIR/Contents/Info.plist"

echo "Validating Info.plist..."
plutil -lint "$BUILD_DIR/Contents/Info.plist"

echo "Verifying LSUIElement..."
PLIST_VALUE=$(defaults read "$(pwd)/$BUILD_DIR/Contents/Info.plist" LSUIElement 2>/dev/null || echo "")
if [ "$PLIST_VALUE" = "1" ]; then
    echo "✓ LSUIElement is set to true"
else
    echo "Error: LSUIElement is not set to true"
    exit 1
fi

echo "Bundle created: $BUILD_DIR"
echo "Run with: open $BUILD_DIR"
