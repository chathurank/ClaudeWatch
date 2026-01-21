import Foundation

enum DisplayMode: String, CaseIterable, Identifiable {
    case maximum = "maximum"
    case fiveHour = "fiveHour"
    case sevenDay = "sevenDay"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .maximum: return "Maximum"
        case .fiveHour: return "5-Hour Window"
        case .sevenDay: return "7-Day Window"
        }
    }
}
