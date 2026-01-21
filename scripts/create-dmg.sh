#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="ClaudeWatch"
DMG_NAME="ClaudeWatch"
VERSION="1.0.0"

echo "📦 Creating DMG installer..."

cd "$PROJECT_DIR"

# Check if app exists
if [ ! -d "$BUILD_DIR/Release/$APP_NAME.app" ]; then
    echo "❌ App not found. Run ./scripts/build-release.sh first"
    exit 1
fi

# Create DMG staging directory
DMG_STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

# Copy app to staging
cp -R "$BUILD_DIR/Release/$APP_NAME.app" "$DMG_STAGING/"

# Note: Applications symlink will be created after mounting the DMG

# Create DMG
DMG_PATH="$BUILD_DIR/${DMG_NAME}-${VERSION}.dmg"
DMG_TEMP="$BUILD_DIR/${DMG_NAME}-temp.dmg"
rm -f "$DMG_PATH" "$DMG_TEMP"

# Create a read-write DMG first
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDRW \
    "$DMG_TEMP"

# Mount the DMG
MOUNT_DIR=$(hdiutil attach -readwrite -noverify "$DMG_TEMP" | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

# Create Finder alias to Applications (preserves icon properly)
osascript << EOF
tell application "Finder"
    make new alias file at POSIX file "$MOUNT_DIR" to POSIX file "/Applications"
    set name of result to "Applications"
end tell
EOF

# Set the Applications folder icon on the alias
ICON_SETTER="$PROJECT_DIR/scripts/seticon"
if [ -f "$ICON_SETTER" ]; then
    # Extract Applications icon if not cached
    if [ ! -f "/tmp/Applications.icns" ]; then
        cat > /tmp/extract_icon.swift << 'SWIFT'
import Cocoa
let icon = NSWorkspace.shared.icon(forFile: "/Applications")
icon.size = NSSize(width: 512, height: 512)
if let tiff = icon.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "/tmp/apps_icon.png"))
}
SWIFT
        swiftc /tmp/extract_icon.swift -o /tmp/extract_icon -framework Cocoa 2>/dev/null && /tmp/extract_icon
        mkdir -p /tmp/Applications.iconset
        for size in 16 32 128 256 512; do
            sips -z $size $size /tmp/apps_icon.png --out /tmp/Applications.iconset/icon_${size}x${size}.png 2>/dev/null
            size2=$((size * 2))
            sips -z $size2 $size2 /tmp/apps_icon.png --out /tmp/Applications.iconset/icon_${size}x${size}@2x.png 2>/dev/null
        done
        iconutil -c icns /tmp/Applications.iconset -o /tmp/Applications.icns 2>/dev/null
    fi
    "$ICON_SETTER" /tmp/Applications.icns "$MOUNT_DIR/Applications" 2>/dev/null || true
fi

# Use AppleScript to configure the window
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {400, 200, 900, 450}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "$APP_NAME.app" of container window to {125, 120}
        set position of item "Applications" of container window to {375, 120}
        close
        open
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

# Sync and unmount
sync
hdiutil detach "$MOUNT_DIR" -quiet

# Convert to compressed read-only DMG
hdiutil convert "$DMG_TEMP" -format UDZO -o "$DMG_PATH"
rm -f "$DMG_TEMP"

# Clean up staging
rm -rf "$DMG_STAGING"

# Get file size
DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)

echo ""
echo "✅ DMG created successfully!"
echo "📍 Location: $DMG_PATH"
echo "📊 Size: $DMG_SIZE"
echo ""
echo "📋 Installation instructions for other Macs:"
echo "   1. Open the DMG file"
echo "   2. Drag 'ClaudeWatch' to the Applications folder"
echo "   3. First launch: Right-click the app → Open → Open"
echo "      (This bypasses Gatekeeper for unsigned apps)"
echo "   4. The app will appear in your menu bar"
