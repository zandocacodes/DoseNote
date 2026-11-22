import Foundation

struct Reminder: Identifiable, Codable, Hashable, Sendable {
    var id: UUID = UUID()
    var name: String
    var hour: Int
    var minute: Int
    var frequency: Frequency
    var firstDay: Date
    var alerts: Bool
    var weekday: Int?

    func weeklyDay(in calendar: Calendar = .current) -> Int {
        weekday ?? calendar.component(.weekday, from: firstDay)
    }

    var scheduledHours: [Int] {
        switch frequency {
        case .twice:
            return [hour, (hour + 12) % 24].sorted()
        case .daily, .weekly:
            return [hour]
        }
    }

    func scheduledTime(on reference: Date = .now, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: reference
        ) ?? reference
    }

    func frequencyDescription(calendar: Calendar = .current) -> String {
        guard frequency == .weekly else {
            return frequency.label
        }
        let index = weeklyDay(in: calendar) - 1
        guard calendar.weekdaySymbols.indices.contains(index) else {
            return frequency.label
        }
        return "Every \(calendar.weekdaySymbols[index])"
    }
}
