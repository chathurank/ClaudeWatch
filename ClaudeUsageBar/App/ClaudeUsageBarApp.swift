import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            UsagePopoverView(viewModel: viewModel)
                .frame(width: 300, height: 390)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
