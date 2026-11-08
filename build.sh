#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "🔨 Building Patro for macOS..."

APP_NAME="Patro"
BUILD_DIR="$DIR/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

# Copy Info.plist
cp "$DIR/Info.plist" "$CONTENTS/Info.plist"

# Copy JS resource
cp "$DIR/Sources/Resources/patro_core.js" "$RESOURCES/patro_core.js"

# Compile Swift sources
SOURCES=(
    "$DIR/Sources/PatroCoreJS.swift"
    "$DIR/Sources/PatroUpdateManager.swift"
    "$DIR/Sources/PatroEngine.swift"
    "$DIR/Sources/PatroView.swift"
    "$DIR/Sources/AppDelegate.swift"
    "$DIR/Sources/main.swift"
)

echo "📦 Compiling Swift sources (Universal Binary: arm64 + x86_64)..."
swiftc -O -module-cache-path /tmp/clang-cache -target arm64-apple-macosx12.0 "${SOURCES[@]}" -o "$BUILD_DIR/patro_arm64"
swiftc -O -module-cache-path /tmp/clang-cache -target x86_64-apple-macosx12.0 "${SOURCES[@]}" -o "$BUILD_DIR/patro_x86_64"
lipo -create -output "$MACOS/$APP_NAME" "$BUILD_DIR/patro_arm64" "$BUILD_DIR/patro_x86_64"
rm -f "$BUILD_DIR/patro_arm64" "$BUILD_DIR/patro_x86_64"

echo "🔏 Ad-hoc code signing..."
codesign --force --deep --sign - "$APP_BUNDLE"

echo "📦 Creating ZIP archive..."
(cd "$BUILD_DIR" && zip -q -r -y "$APP_NAME-macOS.zip" "$APP_NAME.app")

echo "✅ Build complete: $APP_BUNDLE"
echo "✅ Archive: $BUILD_DIR/$APP_NAME-macOS.zip"
echo "To run Patro:"
echo "  open \"$APP_BUNDLE\""
