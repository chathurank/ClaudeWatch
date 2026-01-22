import SwiftUI

struct InstallationGuideView: View {
    let onOpenTerminal: () -> Void
    let onCopyCommand: (String) -> Void
    let onOpenDocs: () -> Void
    let onContinue: () -> Void

    @State private var copiedCommand: String?

    private let installCommand = OnboardingViewModel.installCommand

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)

                Text("Install Claude Code")
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
                        command: installCommand,
                        isCopied: copiedCommand == installCommand,
                        onCopy: {
                            onCopyCommand(installCommand)
                            copiedCommand = installCommand
                            // Reset copied state after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                if copiedCommand == installCommand {
                                    copiedCommand = nil
                                }
                            }
                        }
                    )
                }

                StepRow(number: 3, title: "Wait for installation to complete") {
                    Text("This may require Node.js/npm to be installed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)

            Spacer()

            // Footer
            VStack(spacing: 12) {
                Button(action: onContinue) {
                    Text("Continue to Authentication")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("View Documentation", action: onOpenDocs)
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
    }
}

struct StepRow<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(.blue))

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                content
            }

            Spacer(minLength: 0)
        }
    }
}

struct CommandBox: View {
    let command: String
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(command)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Button(action: onCopy) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .foregroundStyle(isCopied ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(6)
    }
}
