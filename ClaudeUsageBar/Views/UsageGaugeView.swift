import SwiftUI

struct UsageGaugeView: View {
    let value: Double
    let color: Color

    var body: some View {
        ZStack {
            // Background arc
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .rotationEffect(.degrees(135))

            // Value arc
            Circle()
                .trim(from: 0, to: CGFloat(min(value, 100)) / 100 * 0.75)
                .stroke(color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(135))
                .animation(.easeInOut(duration: 0.5), value: value)

            // Center text
            VStack(spacing: 0) {
                Text("\(Int(value))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
