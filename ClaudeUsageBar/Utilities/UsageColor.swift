import SwiftUI

extension Double {
    /// Returns the appropriate color for a usage percentage value
    var usageColor: Color {
        switch self {
        case 0..<50: return .green
        case 50..<80: return .yellow
        case 80..<95: return .orange
        default: return .red
        }
    }
}
