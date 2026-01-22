import SwiftUI

struct AuthenticationGuideView: View {
    let isWaitingForCredentials: Bool
    let onOpenTerminal: () -> Void
    let onCopyCommand: (String) -> Void
    let onSkip: () -> Void

    @State private var copiedCommand: String?

    private let authCommand = OnboardingViewModel.authCommand

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.key.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)

                Text("Authenticate with Claude")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .padding(.top, 8)

            // Steps
            VStack(alignment: .leading, spacing: 16) {
                StepRow(number: 1, title: "Open Terminal") {
                    Button(action: onOpenTerminal) {
                        HStack {
                            Image(systemName: "terminal")
                            Text("Open Terminal")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                StepRow(number: 2, title: "Run this command:") {
                    CommandBox(
                        command: authCommand,
                        isCopied: copiedCommand == authCommand,
                        onCopy: {
                            onCopyCommand(authCommand)
                            copiedCommand = authCommand
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if copiedCommand == authCommand {
                                    copiedCommand = nil
                                }
                            }
                        }
                    )
                }

                StepRow(number: 3, title: "Sign in when prompted") {
                    Text("A browser window will open for authentication.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Auto-detection status
            if isWaitingForCredentials {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)

                    Text("Waiting for authentication...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            // Footer
            Button("Skip for Now", action: onSkip)
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }
}
