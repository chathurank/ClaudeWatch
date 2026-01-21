#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="ClaudeWatch"
BUNDLE_ID="com.claudewatch.app"

echo "🔨 Building ClaudeWatch..."

cd "$PROJECT_DIR"

# Clean previous builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Build Release version
xcodebuild \
    -project ClaudeWatch.xcodeproj \
    -scheme ClaudeWatch \
    -configuration Release \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    CONFIGURATION_BUILD_DIR="$BUILD_DIR/Release" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    clean build

# Check if build succeeded
if [ -d "$BUILD_DIR/Release/$APP_NAME.app" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "📍 App location: $BUILD_DIR/Release/$APP_NAME.app"
    echo ""
    echo "To create a DMG installer, run:"
    echo "  ./scripts/create-dmg.sh"
else
    echo "❌ Build failed!"
    exit 1
fi
