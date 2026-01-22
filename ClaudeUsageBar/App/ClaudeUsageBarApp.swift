import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @StateObject private var usageViewModel = UsageViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    var body: some Scene {
        MenuBarExtra {
            ContentRouterView(
                usageViewModel: usageViewModel,
                onboardingViewModel: onboardingViewModel
            )
            .frame(width: 300, height: 390)
        } label: {
            MenuBarLabel(viewModel: usageViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
