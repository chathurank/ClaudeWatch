# Changelog

All notable changes to ClaudeWatch will be documented in this file.

## [1.1.0] - 2026-01-22

### Added
- **Onboarding flow** for first-time users
  - Welcome screen with app introduction
  - CLI installation detection (checks known paths and PATH)
  - Step-by-step installation guide with copy-to-clipboard commands
  - Authentication guide with auto-detection of credentials
  - Success confirmation screen
- **Setup Guide button** in error states for credential-related issues
- `credentialsExist()` method in KeychainService for lightweight credential polling
- CLIDetectionService for detecting Claude Code CLI installation
- ContentRouterView for routing between onboarding and main usage views

### Changed
- App now shows onboarding flow on first launch instead of error state
- ErrorStateView now offers "Setup Guide" option for credential errors

### Security
- CLI detection uses hardcoded `/usr/bin/which` path with static arguments
- Credential existence check returns boolean only, no credential data exposed
- Only hardcoded trusted URLs (claude.ai/code, docs.anthropic.com)
- Static commands for clipboard operations

## [1.0.0] - 2026-01-21

### Added
- Initial release
- Menu bar app displaying Claude Code CLI usage
- 5-hour and 7-day usage windows with circular gauge
- Adaptive polling (1-10 min based on usage level)
- Display mode selection (Maximum, 5-Hour, 7-Day)
- Secure credential handling via macOS Keychain
- Hardened runtime enabled
