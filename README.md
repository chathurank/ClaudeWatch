# Claude Usage Bar

A native macOS menu bar utility that displays your Claude Code subscription usage.

## Features

- Shows usage percentage directly in the menu bar (color-coded)
- Displays 5-hour and 7-day usage windows with progress bars
- Shows reset countdowns for each limit
- Auto-refreshes (adaptive: more frequent when usage is high)
- Native SwiftUI app (~5MB, no Electron bloat)

## Requirements

- macOS 13.0 (Ventura) or later
- Claude Code CLI installed and authenticated (`claude` command)

## Installation

### Option 1: Download DMG (Easiest)

1. Download `ClaudeUsageBar-1.0.0.dmg` from Releases
2. Open the DMG file
3. Drag "Claude Usage Bar" to Applications
4. **First launch**: Right-click the app → **Open** → **Open**
   (Required once to bypass Gatekeeper for unsigned apps)

### Option 2: Build DMG Installer

1. **Switch to Xcode** (one-time, requires password):
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. **Build and create DMG**:
   ```bash
   ./scripts/build-and-package.sh
   ```

3. The DMG will be created at `build/ClaudeUsageBar-1.0.0.dmg`

### Option 3: Build from Xcode

1. **Switch to Xcode** (one-time setup, requires password):
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

2. **Open in Xcode**:
   ```bash
   open ClaudeUsageBar.xcodeproj
   ```

3. **Build and Run**:
   - Select your Development Team under Signing & Capabilities (or "Sign to Run Locally")
   - Press `Cmd+R` to build and run

## Usage

1. Ensure you're logged into Claude Code:
   ```bash
   claude
   # Follow the authentication prompts if not logged in
   ```

2. Launch Claude Usage Bar from your Applications folder

3. Look for the gauge icon in your menu bar showing your current usage percentage

4. Click the icon to see detailed usage breakdown:
   - 5-hour usage window with reset time
   - 7-day usage window with reset time
   - Subscription type and tier

## Color Coding

- 🟢 **Green** (0-49%): Plenty of capacity
- 🟡 **Yellow** (50-79%): Moderate usage
- 🟠 **Orange** (80-94%): Getting close to limit
- 🔴 **Red** (95-100%): Near or at limit

## Troubleshooting

### "Credentials not found" error
Run `claude` in Terminal to authenticate with your Claude account.

### "Credentials expired" error
Re-authenticate by running `claude` in Terminal.

### App doesn't appear in menu bar
- Check System Settings > Privacy & Security > Accessibility
- Try quitting and relaunching the app

### Build fails with signing error
- Open the project in Xcode
- Go to Signing & Capabilities
- Select your personal team or "Sign to Run Locally"

## How It Works

1. Reads OAuth credentials from macOS Keychain (where Claude CLI stores them)
2. Calls the Anthropic usage API directly
3. Displays results in a native SwiftUI popover
4. Refreshes automatically every 5 minutes (adapts based on usage level)

## Project Structure

```
ClaudeUsageBar/
├── App/
│   └── ClaudeUsageBarApp.swift      # MenuBarExtra entry point
├── Models/
│   ├── UsageData.swift              # API response models
│   ├── Credentials.swift            # OAuth credential model
│   └── UsageError.swift             # Error types
├── ViewModels/
│   └── UsageViewModel.swift         # State management
├── Views/
│   ├── MenuBarLabel.swift           # Menu bar icon + text
│   ├── UsagePopoverView.swift       # Dropdown content
│   ├── UsageGaugeView.swift         # Circular gauge
│   └── UsageDetailRow.swift         # Usage row component
└── Services/
    ├── KeychainService.swift        # Keychain access
    ├── APIService.swift             # HTTP client
    └── PollingService.swift         # Timer-based refresh
```

## License

MIT License - feel free to modify and distribute.

## Credits

Built with SwiftUI for macOS. Uses the Anthropic OAuth usage API.
