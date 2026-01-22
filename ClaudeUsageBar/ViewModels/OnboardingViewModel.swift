import Foundation
import SwiftUI
import AppKit

/// Manages onboarding state and credential detection
@MainActor
final class OnboardingViewModel: ObservableObject {
    // Published state
    @Published private(set) var state: OnboardingState = .welcome
    @Published private(set) var isCheckingCredentials = false

    // First launch tracking
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false

    // Services
    private let cliDetectionService: CLIDetectionService
    private let keychainService: KeychainService

    // Credential polling timer
    private var credentialPollingTimer: Timer?
    private let credentialPollingInterval: TimeInterval = 3.0

    // Hardcoded trusted URLs (security: no dynamic URL construction)
    static let claudeCodeURL = URL(string: "https://claude.ai/code")!
    static let claudeDocsURL = URL(string: "https://docs.anthropic.com/en/docs/claude-code")!

    // Installation command (static, for clipboard)
    static let installCommand = "npm install -g @anthropic-ai/claude-code"
    static let authCommand = "claude"

    init(
        cliDetectionService: CLIDetectionService = .shared,
        keychainService: KeychainService = .shared
    ) {
        self.cliDetectionService = cliDetectionService
        self.keychainService = keychainService
    }

    /// Determines if onboarding should be shown
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// Starts the onboarding flow
    func startOnboarding() {
        state = .welcome
    }

    /// Called when user clicks "Get Started" on welcome screen
    func proceedFromWelcome() {
        state = .checkingCLI
        checkCLIInstallation()
    }

    /// Checks if CLI is installed and credentials exist
    func checkCLIInstallation() {
        state = .checkingCLI

        // Perform check on background thread to avoid UI blocking
        Task {
            let cliInstalled = await Task.detached(priority: .userInitiated) {
                CLIDetectionService.shared.isCLIInstalled()
            }.value
            let credentialsExist = await Task.detached(priority: .userInitiated) {
                KeychainService.shared.credentialsExist()
            }.value

            handleCheckResult(cliInstalled: cliInstalled, credentialsExist: credentialsExist)
        }
    }

    private func handleCheckResult(cliInstalled: Bool, credentialsExist: Bool) {
        if !cliInstalled {
            state = .cliNotFound
        } else if !credentialsExist {
            state = .cliNotAuthenticated
        } else {
            completeOnboarding()
        }
    }

    /// User indicates they want to see installation instructions
    func showInstallationGuide() {
        state = .installationGuide
    }

    /// User indicates they want to see authentication guide
    func showAuthenticationGuide() {
        state = .authenticationGuide
        startCredentialPolling()
    }

    /// User indicates they've installed CLI, recheck
    func recheckCLI() {
        checkCLIInstallation()
    }

    /// Completes onboarding and transitions to main view
    func completeOnboarding() {
        stopCredentialPolling()
        state = .complete
        hasCompletedOnboarding = true
    }

    /// Resets onboarding state (for testing or re-onboarding)
    func resetOnboarding() {
        stopCredentialPolling()
        hasCompletedOnboarding = false
        state = .welcome
    }

    // MARK: - Credential Polling

    /// Starts polling for credentials during authentication guide
    private func startCredentialPolling() {
        stopCredentialPolling()
        isCheckingCredentials = true

        credentialPollingTimer = Timer.scheduledTimer(withTimeInterval: credentialPollingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkForCredentials()
            }
        }
    }

    /// Stops credential polling
    func stopCredentialPolling() {
        credentialPollingTimer?.invalidate()
        credentialPollingTimer = nil
        isCheckingCredentials = false
    }

    /// Checks if credentials now exist
    private func checkForCredentials() async {
        let exists = await Task.detached(priority: .userInitiated) {
            KeychainService.shared.credentialsExist()
        }.value

        if exists {
            stopCredentialPolling()
            state = .complete
            hasCompletedOnboarding = true
        }
    }

    // MARK: - Actions

    /// Opens Claude Code installation page
    func openInstallPage() {
        NSWorkspace.shared.open(Self.claudeCodeURL)
    }

    /// Opens Claude Code documentation
    func openDocumentation() {
        NSWorkspace.shared.open(Self.claudeDocsURL)
    }

    /// Opens Terminal.app
    func openTerminal() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
    }

    /// Copies text to clipboard
    func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
