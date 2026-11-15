#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

echo "🔨 Building FloatingNotes (Release)..."
swift build -c release

APP_NAME="FloatingNotes.app"
BUILD_DIR="$DIR/build"
APP_DIR="$BUILD_DIR/$APP_NAME"
MACOS_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

echo "📦 Packaging $APP_NAME..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$DIR/.build/release/FloatingNotes" "$MACOS_DIR/FloatingNotes"
cp "$DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

echo "✅ App bundle created at: $APP_DIR"
echo "You can launch it by running: open \"$APP_DIR\""
