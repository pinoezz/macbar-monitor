#!/bin/bash
set -euo pipefail

APP_NAME="MacBarMonitor"
BUILD_DIR="MacBarMonitor.app"
RELEASE_BINARY=".build/release/MacBarMonitor"
DMG_NAME="MacBarMonitor-v2.0.3.dmg"
DMG_VOLUME_NAME="MacBar Monitor"
DMG_STAGING="dmg_staging"

echo "=== MacBar Monitor DMG Builder ==="
echo ""

# Step 1: Build release binary
echo "Step 1: Building release binary..."
swift build -c release

if [ ! -f "$RELEASE_BINARY" ]; then
    echo "Error: Release binary not found at $RELEASE_BINARY"
    exit 1
fi

# Step 2: Create app bundle
echo "Step 2: Creating app bundle..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/Contents/MacOS"
mkdir -p "$BUILD_DIR/Contents/Resources"

cp "$RELEASE_BINARY" "$BUILD_DIR/Contents/MacOS/$APP_NAME"
cp "Sources/MacBarMonitor/Info.plist" "$BUILD_DIR/Contents/Info.plist"

echo "Validating Info.plist..."
plutil -lint "$BUILD_DIR/Contents/Info.plist"

# Step 3: Create DMG
echo "Step 3: Creating DMG..."
rm -rf "$DMG_STAGING"
rm -f "$DMG_NAME"

mkdir -p "$DMG_STAGING"
cp -R "$BUILD_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create DMG using hdiutil
hdiutil create \
    -volname "$DMG_VOLUME_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_NAME"

# Cleanup staging
rm -rf "$DMG_STAGING"

echo ""
echo "=== Build Complete ==="
echo "App bundle: $BUILD_DIR"
echo "DMG installer: $DMG_NAME"
echo ""
echo "To install:"
echo "  1. Open $DMG_NAME"
echo "  2. Drag MacBarMonitor to Applications"
echo "  3. Open from Applications"
