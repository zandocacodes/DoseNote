import Foundation

struct WatchSnapshot: Codable, Sendable {
    var schedule: Schedule
    var updatedAt: Date = .now
}
