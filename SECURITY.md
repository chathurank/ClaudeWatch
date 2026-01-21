# Security Policy

## Overview

ClaudeWatch is a macOS menu bar utility that displays your Claude Code subscription usage. This document describes the security measures in place and how sensitive data is handled.

## Data Access

### What ClaudeWatch Accesses

1. **OAuth Credentials (Read-Only)**
   - Reads the `Claude Code-credentials` item from macOS Keychain
   - This is the same credential stored by the official Claude CLI
   - ClaudeWatch **never writes** to the Keychain
   - Tokens are used only for API requests, then cleared from memory

2. **Anthropic API**
   - Makes HTTPS requests to `api.anthropic.com/api/oauth/usage`
   - Only retrieves usage statistics (utilization percentages, reset times)
   - No personal data, conversation history, or other information is accessed

### What ClaudeWatch Does NOT Do

- Does not store tokens persistently
- Does not send data to any third-party servers
- Does not access your Claude conversations
- Does not modify any credentials
- Does not require network access except to Anthropic's API

## Security Measures

### Hardened Runtime
The app is built with macOS Hardened Runtime enabled, which provides:
- Code signing enforcement
- Library validation
- Protection against code injection
- Memory protection

### Certificate Pinning
HTTPS connections to the Anthropic API use certificate pinning to prevent man-in-the-middle attacks. The app validates server certificates against known public key hashes.

### Secure Network Configuration
- Uses ephemeral URLSession (no persistent cache)
- No cookies stored
- No URL caching
- Strict transport security (HTTPS only)

### Memory Security
- OAuth tokens are overwritten in memory after use
- Session timeout after 8 hours requires credential re-validation
- No sensitive data logged or persisted

### Input Validation
- API responses are validated for expected ranges
- Malformed responses are rejected

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email the maintainers directly or use GitHub's private vulnerability reporting
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Any suggested fixes (optional)

We will acknowledge receipt within 48 hours and provide a detailed response within 7 days.

## Third-Party Dependencies

ClaudeWatch has **no third-party dependencies**. It uses only:
- Apple's native frameworks (SwiftUI, Foundation, Security, CommonCrypto)
- Anthropic's public OAuth usage API

## Code Signing

The distributed DMG is ad-hoc signed for personal use. This means:
- macOS Gatekeeper will show a warning on first launch
- Users must right-click and select "Open" to bypass this warning
- This is normal for apps not distributed through the Mac App Store

For enterprise deployment, you can build and sign with your own Apple Developer certificate.

## Privacy

ClaudeWatch collects no analytics, telemetry, or user data. All operations happen locally on your Mac, with the only network traffic being HTTPS requests to Anthropic's API to fetch your usage statistics.
