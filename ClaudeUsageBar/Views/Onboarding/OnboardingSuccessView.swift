import SwiftUI

struct OnboardingSuccessView: View {
    let onViewUsage: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            // Message
            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("ClaudeWatch is now connected to your Claude Code account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }

            Spacer()

            // Continue button
            Button(action: onViewUsage) {
                Text("View Usage")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}
