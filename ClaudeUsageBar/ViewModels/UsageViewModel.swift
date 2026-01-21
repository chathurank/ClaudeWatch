import Foundation
import Combine
import SwiftUI
import AppKit

@MainActor
final class UsageViewModel: ObservableObject {
    // Published state
    @Published private(set) var usageData: UsageData?
    @Published private(set) var isLoading = false
    @Published private(set) var error: UsageError?
    @Published private(set) var lastUpdated: Date?

    // Non-sensitive display info (extracted from credentials, tokens not stored)
    @Published private(set) var subscriptionTypeValue: String = "Unknown"
    @Published private(set) var rateLimitTierValue: String = "Unknown"

    // User settings
    @AppStorage("displayMode") var displayMode: String = DisplayMode.maximum.rawValue

    // Services
    private let keychainService: KeychainService
    private let apiService: APIService
    private let pollingService: PollingService

    // Wake notification observer
    private var wakeObserver: NSObjectProtocol?

    // Thread safety: prevents concurrent refresh operations
    private var isRefreshing = false

    // Session timeout: require credential re-validation after 8 hours
    private var sessionStartTime: Date?
    private let maxSessionDuration: TimeInterval = 3600 * 8 // 8 hours

    // Computed properties for UI
    var fiveHourUsagePercent: Double {
        usageData?.fiveHour.utilization ?? 0
    }

    var sevenDayUsagePercent: Double {
        usageData?.sevenDay.utilization ?? 0
    }

    var currentDisplayMode: DisplayMode {
        get { DisplayMode(rawValue: displayMode) ?? .maximum }
        set { displayMode = newValue.rawValue }
    }

    var primaryUsagePercent: Double {
        switch currentDisplayMode {
        case .maximum:
            return max(fiveHourUsagePercent, sevenDayUsagePercent)
        case .fiveHour:
            return fiveHourUsagePercent
        case .sevenDay:
            return sevenDayUsagePercent
        }
    }

    var fiveHourResetTime: Date? {
        usageData?.fiveHour.resetsAt
    }

    var sevenDayResetTime: Date? {
        usageData?.sevenDay.resetsAt
    }

    var subscriptionType: String {
        subscriptionTypeValue
    }

    var rateLimitTier: String {
        rateLimitTierValue
    }

    var menuBarTitle: String {
        if error != nil {
            return "!"
        }
        if isLoading && usageData == nil {
            return "..."
        }
        return "\(Int(primaryUsagePercent))%"
    }

    var usageColor: Color {
        primaryUsagePercent.usageColor
    }

    init(
        keychainService: KeychainService = .shared,
        apiService: APIService = .shared,
        pollingService: PollingService = PollingService()
    ) {
        self.keychainService = keychainService
        self.apiService = apiService
        self.pollingService = pollingService

        setupPolling()
        setupWakeNotification()
    }

    deinit {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func setupWakeNotification() {
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshUsage()
            }
        }
    }

    private func setupPolling() {
        pollingService.onPoll = { [weak self] in
            await self?.refreshUsage()
        }
        pollingService.start()
    }

    /// Validates that the current session hasn't exceeded the maximum duration.
    /// Returns true if session is valid, false if re-authentication is needed.
    private func validateSession() -> Bool {
        guard let start = sessionStartTime else {
            sessionStartTime = Date()
            return true
        }
        return Date().timeIntervalSince(start) < maxSessionDuration
    }

    /// Resets the session, clearing cached state and requiring fresh credentials
    private func invalidateSession() {
        sessionStartTime = nil
        usageData = nil
        apiService.resetBackoffState()
    }

    func refreshUsage() async {
        // Thread safety: prevent concurrent refresh operations
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        // Session timeout check
        if !validateSession() {
            invalidateSession()
            error = .authError("Session expired. Please re-authenticate with Claude CLI.")
            isLoading = false
            return
        }

        isLoading = true
        error = nil

        do {
            // Fetch credentials, extract only what's needed, don't store tokens
            let creds = try keychainService.getCredentials()

            // Copy token to local variable for use, then clear after
            var accessToken = creds.claudeAiOauth.accessToken
            defer {
                // Overwrite the token in memory after use
                // Note: Swift strings are value types, so this clears the local copy
                accessToken = String(repeating: "\0", count: accessToken.count)
            }

            // Extract non-sensitive display info
            subscriptionTypeValue = creds.claudeAiOauth.subscriptionType.capitalized
            rateLimitTierValue = creds.claudeAiOauth.rateLimitTier
                .replacingOccurrences(of: "default_claude_", with: "")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized

            // Fetch usage data (token used only for this call, not stored)
            let usage = try await apiService.fetchUsage(accessToken: accessToken)
            usageData = usage
            lastUpdated = Date()

            // Adjust polling interval based on usage
            updatePollingInterval()

        } catch let usageError as UsageError {
            error = usageError
        } catch {
            self.error = .networkError(error)
        }

        isLoading = false
    }

    private func updatePollingInterval() {
        let maxUsage = primaryUsagePercent
        let newInterval: TimeInterval

        switch maxUsage {
        case 0..<20: newInterval = 600   // 10 minutes
        case 20..<50: newInterval = 300  // 5 minutes
        case 50..<80: newInterval = 180  // 3 minutes
        case 80..<95: newInterval = 120  // 2 minutes
        default: newInterval = 60        // 1 minute when critical
        }

        if pollingService.pollInterval != newInterval {
            pollingService.pollInterval = newInterval
        }
    }

    func retryAfterError() async {
        error = nil
        await refreshUsage()
    }
}
