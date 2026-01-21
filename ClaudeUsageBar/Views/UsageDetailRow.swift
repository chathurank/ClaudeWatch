import SwiftUI

struct UsageDetailRow: View {
    let title: String
    let percentage: Double
    let resetTime: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(percentage))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)

                    Rectangle()
                        .fill(percentage.usageColor)
                        .frame(width: geometry.size.width * CGFloat(min(percentage, 100)) / 100, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 4)

            if let reset = resetTime {
                Text("Resets \(reset, style: .relative)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}
