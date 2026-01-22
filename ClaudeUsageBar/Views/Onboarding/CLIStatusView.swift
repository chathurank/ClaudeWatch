import SwiftUI

struct CLIStatusView: View {
    let isChecking: Bool
    let cliFound: Bool
    let onInstall: () -> Void
    let onRecheck: () -> Void
    let onShowGuide: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            if isChecking {
                checkingView
            } else if cliFound {
                cliFoundView
            } else {
                cliNotFoundView
            }

            Spacer()
        }
        .padding(24)
    }

    private var checkingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Checking for Claude Code CLI...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var cliFoundView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Claude Code CLI Found")
                .font(.headline)

            Text("CLI is installed. Checking authentication...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var cliNotFoundView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            VStack(spacing: 8) {
                Text("Claude Code CLI Not Found")
                    .font(.headline)

                Text("ClaudeWatch requires the Claude Code CLI to access your usage data.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: onInstall) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Install Claude Code")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("View Installation Guide", action: onShowGuide)
                    .buttonStyle(.bordered)
                    .controlSize(.regular)

                Button("I've Already Installed It", action: onRecheck)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
