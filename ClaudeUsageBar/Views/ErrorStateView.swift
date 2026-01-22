import SwiftUI

struct ErrorStateView: View {
    let error: UsageError
    let onRetry: () -> Void
    var onShowSetupGuide: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconForError)
                .font(.system(size: 32))
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if let recovery = error.recoverySuggestion {
                Text(recovery)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 8) {
                Button("Retry") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                // Show setup guide button for credential-related errors
                if showSetupGuideButton, let onShowSetupGuide = onShowSetupGuide {
                    Button("Setup Guide") {
                        onShowSetupGuide()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
    }

    private var iconForError: String {
        switch error {
        case .credentialsNotFound, .credentialsExpired:
            return "key.slash"
        case .networkError:
            return "wifi.slash"
        case .apiError:
            return "exclamationmark.icloud"
        default:
            return "exclamationmark.triangle"
        }
    }

    /// Determines if the setup guide button should be shown
    private var showSetupGuideButton: Bool {
        switch error {
        case .credentialsNotFound, .credentialsExpired, .credentialsInvalid:
            return true
        case .apiError(let code, _) where code == 401 || code == 403:
            return true
        case .authError:
            return true
        default:
            return false
        }
    }
}
