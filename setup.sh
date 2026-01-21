#!/bin/bash

set -e

echo "Setting up ClaudeUsageBar..."

# Check if xcodegen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "xcodegen not found. Installing via Homebrew..."

    if ! command -v brew &> /dev/null; then
        echo "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi

    brew install xcodegen
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "✅ Project generated successfully!"
echo ""
echo "To build and run:"
echo "  1. Open ClaudeUsageBar.xcodeproj in Xcode"
echo "  2. Select your Development Team in Signing & Capabilities"
echo "  3. Press Cmd+R to build and run"
echo ""
echo "Or build from command line:"
echo "  xcodebuild -project ClaudeUsageBar.xcodeproj -scheme ClaudeUsageBar -configuration Release build"
