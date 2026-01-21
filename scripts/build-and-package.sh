#!/bin/bash

# Complete build and package script
# Run this to create a distributable DMG

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 ClaudeWatch - Build & Package"
echo "================================="
echo ""

# Check xcode-select
XCODE_PATH=$(xcode-select -p 2>/dev/null || echo "")
if [[ "$XCODE_PATH" != *"Xcode.app"* ]]; then
    echo "⚠️  Xcode is not the active developer directory."
    echo ""
    echo "Please run this command first (requires password):"
    echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Build
"$SCRIPT_DIR/build-release.sh"

# Create DMG
"$SCRIPT_DIR/create-dmg.sh"

echo ""
echo "🎉 All done! Your installer is ready to distribute."
