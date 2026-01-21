# ClaudeWatch - Project Documentation

A native macOS menu bar app that displays Claude Code CLI subscription usage.

## Quick Reference

### Build & Run
```bash
# Rebuild and create DMG
./scripts/build-and-package.sh

# Or just build
./scripts/build-release.sh

# Launch app
open "build/Release/ClaudeWatch.app"

# Kill running instance
pkill -f "ClaudeWatch"
```

### Project Structure
```
ClaudeUsageBar/
├── App/
│   └── ClaudeUsageBarApp.swift      # Entry point - MenuBarExtra scene
├── Models/
│   ├── UsageData.swift              # API response: five_hour, seven_day utilization
│   ├── Credentials.swift            # OAuth creds from Keychain (fields are optional)
│   ├── DisplayMode.swift            # Enum for display mode preference
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
├── Utilities/
│   └── UsageColor.swift             # Color extension for usage percentages
└── Resources/
    ├── Info.plist                   # LSUIElement=true (menu bar agent)
    └── Assets.xcassets/             # App icon (gauge design)
```

## Rules & Guidelines

### Security Rules (CRITICAL)
1. **Never log or print OAuth tokens** - tokens should only exist in memory briefly
2. **Never store tokens persistently** - always read fresh from Keychain
3. **Clear tokens from memory after use** - overwrite with null bytes
4. **Sanitize error messages** - never expose token values or internal details to users
5. **Use ephemeral URLSession** - no caching, no cookies
6. **Validate API responses** - check utilization is within 0-100 range
7. **Keep hardened runtime enabled** - protects against code injection

### Code Style Rules
1. **Use @MainActor for ViewModels** - all UI state must be on main thread
2. **Make credential fields optional** - API may return null for subscriptionType, rateLimitTier, scopes
3. **Handle all error cases** - never let errors fail silently
4. **Use defer for cleanup** - especially for clearing sensitive data
5. **Prefer guard for early returns** - improves readability

### Pre-Commit Requirements (MANDATORY)
Before EVERY commit, you MUST complete both the security audit and smoke test.

#### Security Audit Checklist
Run before every commit:
1. **Token handling**: Verify no tokens are logged, stored, or exposed in error messages
2. **Hardened runtime**: Confirm `ENABLE_HARDENED_RUNTIME: YES` in `project.yml`
3. **Ephemeral session**: Verify URLSession uses ephemeral config with no caching
4. **Input validation**: Check API response validation is in place
5. **Error sanitization**: Verify error messages don't expose sensitive details
6. **No secrets in code**: Search for hardcoded tokens/keys: `grep -r "sk-ant" ClaudeUsageBar/`
7. **Memory clearing**: Verify tokens are overwritten after use with null bytes

#### Smoke Test Checklist
Run after every build:
1. Clean build: `rm -rf build/ && ./scripts/build-and-package.sh`
2. Kill existing instances: `pkill -f "ClaudeWatch"`
3. Launch fresh: `open "build/Release/ClaudeWatch.app"`
4. **Test valid credentials**: Should show usage percentages
5. **Test retry button**: Click retry, should show loading then result
6. **Test refresh button**: Click refresh icon in header
7. **Test quit button**: Should terminate app
8. Verify no sensitive data in console: `log show --predicate 'subsystem == "com.claudewatch.app"' --last 5m`

#### Quick Verification Commands
```bash
# Security check - search for potential token leaks
grep -rn "accessToken\|refreshToken" ClaudeUsageBar/ | grep -v "let \|var \|\.accessToken\|\.refreshToken"

# Verify hardened runtime
grep -A1 "ENABLE_HARDENED_RUNTIME" project.yml

# Verify ephemeral session
grep -A5 "URLSessionConfiguration" ClaudeUsageBar/Services/APIService.swift
```

## Architecture

### Data Flow
1. `KeychainService` reads OAuth token from macOS Keychain (service: "Claude Code-credentials")
2. `APIService` calls `GET https://api.anthropic.com/api/oauth/usage` with Bearer token
3. `UsageViewModel` stores response and updates `@Published` properties
4. SwiftUI views react to state changes automatically
5. `PollingService` triggers refresh (adaptive: 1-10 min based on usage level)

### Security Architecture
- **Hardened Runtime**: Enabled for code injection protection
- **Ephemeral Sessions**: URLSession configured with no caching/cookies
- **Token Lifecycle**: Read from Keychain → Use for single request → Overwrite in memory
- **Session Timeout**: 8-hour maximum session before requiring credential re-validation
- **Rate Limiting**: 5-second minimum between requests + exponential backoff on 429
- **Input Validation**: API response values validated before use

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
| Add new error types | `Models/UsageError.swift` |

## API Details

### Endpoint
```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <accessToken>
anthropic-beta: oauth-2025-04-20
```

### Required OAuth Scope
The token must have `user:profile` scope. If missing, API returns 403.

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
    "scopes": ["user:inference", "user:profile"],
    "subscriptionType": "max",        // May be null
    "rateLimitTier": "default_claude_max_20x"  // May be null
  }
}
```

**Important**: `subscriptionType`, `rateLimitTier`, and `scopes` can be null. The `Credentials.swift` model uses optionals for these fields.

## Common Issues & Fixes

### "Invalid response from server" error
**Cause**: Credentials model fields don't match actual JSON structure.
**Fix**: Ensure optional fields in `Credentials.swift` match API response. Fields like `subscriptionType` and `rateLimitTier` may be null.

### "Access denied" error (403)
**Cause**: OAuth token missing required `user:profile` scope.
**Fix**: User must re-authenticate: `claude` (may need to logout first with `/logout`)

### Retry button shows blank state
**Cause**: View priority issue - error cleared before loading state set.
**Fix**: In `UsagePopoverView.swift`, check `isLoading` FIRST, then error, then data.

### Certificate pinning failures
**Note**: Certificate pinning was removed due to frequent CA changes. App uses standard TLS which is sufficient for this use case.

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
Edit `Utilities/UsageColor.swift`:
```swift
var usageColor: Color {
    switch self {
    case 0..<50: return .green
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

## Build & Release

### Local Development
```bash
xcodegen generate
./scripts/build-and-package.sh
open "build/Release/ClaudeWatch.app"
```

### Creating a Release
```bash
# Build
./scripts/build-and-package.sh

# Create GitHub release
gh release create v1.x.x ./build/ClaudeWatch-1.0.0.dmg --title "ClaudeWatch v1.x.x" --notes "Release notes here"
```

## Notes

- App runs without sandbox to access Claude Code's Keychain item
- No code signing required for personal use (right-click → Open to bypass Gatekeeper)
- Polling adapts: 1-10 min intervals based on usage level
- GitHub repo: https://github.com/chathurank/ClaudeWatch
- Landing page: https://chathurank.github.io/ClaudeWatch/
