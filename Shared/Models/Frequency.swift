import Foundation

enum Frequency: String, CaseIterable, Codable, Hashable, Sendable {
    case daily = "Every day"
    case twice = "Every 12 hours"
    case weekly = "Every week"

    var label: String {
        rawValue
    }
}
