import Foundation

struct UsageData: Codable, Equatable {
    let fiveHour: UsageLimit
    let sevenDay: UsageLimit

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}

struct UsageLimit: Codable, Equatable {
    let utilization: Double
    let resetsAt: Date

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}
