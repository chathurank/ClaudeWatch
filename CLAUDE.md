# Claude Usage Bar - Project Documentation

A native macOS menu bar app that displays Claude Code CLI subscription usage.

## Quick Reference

### Build & Run
```bash
# Rebuild and create DMG
./scripts/build-and-package.sh

# Or just build
./scripts/build-release.sh

# Launch app
open "build/Release/Claude Usage Bar.app"
```

### Project Structure
```
ClaudeUsageBar/
├── App/
│   └── ClaudeUsageBarApp.swift      # Entry point - MenuBarExtra scene
├── Models/
│   ├── UsageData.swift              # API response: five_hour, seven_day utilization
│   ├── Credentials.swift            # OAuth creds from Keychain
│   └── UsageError.swift             # Error enum with recovery suggestions
├── ViewModels/
│   └── UsageViewModel.swift         # Main state: usageData, isLoading, error
├── Views/
│   ├── MenuBarLabel.swift           # Menu bar icon + percentage text
│   ├── UsagePopoverView.swift       # Main dropdown UI
│   ├── UsageGaugeView.swift         # Circular gauge component
│   ├── UsageDetailRow.swift         # Progress bar row component
│   ├── ErrorStateView.swift         # Error display with retry
│   └── LoadingView.swift            # Loading spinner
├── Services/
│   ├── KeychainService.swift        # Reads "Claude Code-credentials" from Keychain
│   ├── APIService.swift             # Calls api.anthropic.com/api/oauth/usage
│   └── PollingService.swift         # Timer-based auto-refresh
└── Resources/
    ├── Info.plist                   # LSUIElement=true (menu bar agent)
    └── Assets.xcassets/             # App icon (gauge design)
```

## Architecture

### Data Flow
1. `KeychainService` reads OAuth token from macOS Keychain (service: "Claude Code-credentials")
2. `APIService` calls `GET https://api.anthropic.com/api/oauth/usage` with Bearer token
3. `UsageViewModel` stores response and updates `@Published` properties
4. SwiftUI views react to state changes automatically
5. `PollingService` triggers refresh every 5 minutes (adaptive based on usage level)

### Key Files to Modify

| Task | File(s) |
|------|---------|
| Change UI layout | `Views/UsagePopoverView.swift` |
| Modify gauge appearance | `Views/UsageGaugeView.swift` |
| Add new data fields | `Models/UsageData.swift`, `ViewModels/UsageViewModel.swift` |
| Change refresh interval | `Services/PollingService.swift`, `UsageViewModel.swift` |
| Update API endpoint | `Services/APIService.swift` |
| Change menu bar display | `Views/MenuBarLabel.swift` |
| Modify app icon | `scripts/generate-icon.swift`, then run it |

## API Details

### Endpoint
```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <accessToken>
anthropic-beta: oauth-2025-04-20
```

### Response
```json
{
  "five_hour": {
    "utilization": 12.5,
    "resets_at": "2025-01-13T18:00:00Z"
  },
  "seven_day": {
    "utilization": 45.0,
    "resets_at": "2025-01-20T00:00:00Z"
  }
}
```

### Keychain Credential Structure
```json
{
  "claudeAiOauth": {
    "accessToken": "sk-ant-oat01-...",
    "refreshToken": "sk-ant-ort01-...",
    "expiresAt": 1768315266012,
    "subscriptionType": "max",
    "rateLimitTier": "default_claude_max_20x"
  }
}
```

## Common Modifications

### Add a new usage metric
1. Update `Models/UsageData.swift` - add property to `UsageData` struct
2. Update `ViewModels/UsageViewModel.swift` - add computed property
3. Update `Views/UsagePopoverView.swift` - add UI element

### Change polling interval
Edit `UsageViewModel.swift`:
```swift
private func updatePollingInterval() {
    // Modify the switch cases for different intervals
}
```

### Change color thresholds
Edit `UsageViewModel.swift`:
```swift
var usageColor: Color {
    let percent = primaryUsagePercent
    switch percent {
    case 0..<50: return .green    // Modify these ranges
    case 50..<80: return .yellow
    // ...
    }
}
```

### Regenerate app icon
```bash
swift scripts/generate-icon.swift ClaudeUsageBar/Resources/Assets.xcassets/AppIcon.appiconset
```

## Dependencies

- **macOS 13.0+** (Ventura) - for MenuBarExtra API
- **Swift 5.9+**
- **Xcode 15+** - for building
- **xcodegen** - for project generation (`brew install xcodegen`)

## Troubleshooting

### "Credentials not found" error
User needs to run `claude` CLI to authenticate first.

### Build fails
```bash
# Ensure Xcode is selected
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

# Regenerate project
xcodegen generate
```

### App doesn't appear in menu bar
Check if another instance is running: `pkill -f "Claude Usage Bar"`

## Notes

- App runs without sandbox to access Claude Code's Keychain item
- No code signing required for personal use (right-click → Open to bypass Gatekeeper)
- Polling adapts: 1-10 min intervals based on usage level
