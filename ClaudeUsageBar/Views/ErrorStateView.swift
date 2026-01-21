import SwiftUI

struct ErrorStateView: View {
    let error: UsageError
    let onRetry: () -> Void

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

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
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
}
