import SwiftUI

/// Routes between onboarding flow and main usage view
struct ContentRouterView: View {
    @ObservedObject var usageViewModel: UsageViewModel
    @ObservedObject var onboardingViewModel: OnboardingViewModel

    /// Track if we're showing setup guide from error state
    @State private var showingSetupGuide = false

    var body: some View {
        Group {
            if showingSetupGuide || onboardingViewModel.shouldShowOnboarding || onboardingViewModel.state != .complete {
                OnboardingContainerView(
                    viewModel: onboardingViewModel,
                    onComplete: {
                        showingSetupGuide = false
                    }
                )
            } else {
                UsagePopoverView(
                    viewModel: usageViewModel,
                    onShowSetupGuide: {
                        // Reset onboarding to show authentication guide
                        onboardingViewModel.showAuthenticationGuide()
                        showingSetupGuide = true
                    }
                )
            }
        }
        .frame(width: 300, height: 390)
    }
}

/// Container view for all onboarding screens
struct OnboardingContainerView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var onComplete: (() -> Void)?

    var body: some View {
        switch viewModel.state {
        case .welcome:
            WelcomeView(onGetStarted: viewModel.proceedFromWelcome)

        case .checkingCLI:
            CLIStatusView(
                isChecking: true,
                cliFound: false,
                onInstall: viewModel.openInstallPage,
                onRecheck: viewModel.recheckCLI,
                onShowGuide: viewModel.showInstallationGuide
            )

        case .cliNotFound:
            CLIStatusView(
                isChecking: false,
                cliFound: false,
                onInstall: viewModel.openInstallPage,
                onRecheck: viewModel.recheckCLI,
                onShowGuide: viewModel.showInstallationGuide
            )

        case .cliNotAuthenticated:
            CLIStatusView(
                isChecking: false,
                cliFound: true,
                onInstall: viewModel.openInstallPage,
                onRecheck: viewModel.recheckCLI,
                onShowGuide: viewModel.showAuthenticationGuide
            )

        case .installationGuide:
            InstallationGuideView(
                onOpenTerminal: viewModel.openTerminal,
                onCopyCommand: viewModel.copyToClipboard,
                onOpenDocs: viewModel.openDocumentation,
                onContinue: viewModel.showAuthenticationGuide
            )

        case .authenticationGuide:
            AuthenticationGuideView(
                isWaitingForCredentials: viewModel.isCheckingCredentials,
                onOpenTerminal: viewModel.openTerminal,
                onCopyCommand: viewModel.copyToClipboard,
                onSkip: {
                    viewModel.completeOnboarding()
                    onComplete?()
                }
            )

        case .complete:
            OnboardingSuccessView(onViewUsage: {
                viewModel.completeOnboarding()
                onComplete?()
            })
        }
    }
}
