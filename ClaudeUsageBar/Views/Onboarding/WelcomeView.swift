import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 80, height: 80)
                .cornerRadius(16)

            // Title and description
            VStack(spacing: 8) {
                Text("Welcome to ClaudeWatch")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Monitor your Claude Code CLI usage directly from your menu bar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()

            // Get Started button
            Button(action: onGetStarted) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}
