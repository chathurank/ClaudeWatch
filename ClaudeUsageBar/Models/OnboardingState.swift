import Foundation

/// Represents the current step in the onboarding flow
enum OnboardingState: Equatable {
    /// Initial welcome screen
    case welcome

    /// Checking if CLI is installed
    case checkingCLI

    /// CLI not found, showing installation guide
    case cliNotFound

    /// CLI found but not authenticated
    case cliNotAuthenticated

    /// Showing step-by-step installation instructions
    case installationGuide

    /// Showing authentication instructions with auto-detection
    case authenticationGuide

    /// Setup complete, ready to show main view
    case complete
}
