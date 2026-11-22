import Foundation

struct Schedule: Codable, Hashable, Sendable {
    var reminders: [Reminder] = []
    var records: [String: DoseRecord] = [:]

    func doses(on day: Date, calendar: Calendar = .current) -> [Dose] {
        let startOfDay = calendar.startOfDay(for: day)

        return reminders
            .flatMap { reminder -> [Dose] in
                let reminderStartDay = calendar.startOfDay(for: reminder.firstDay)
                guard startOfDay >= reminderStartDay else {
                    return []
                }

                if reminder.frequency == .weekly,
                   calendar.component(.weekday, from: day) != reminder.weeklyDay(in: calendar) {
                    return []
                }

                return reminder.scheduledHours.compactMap { hour in
                    if calendar.isDate(day, inSameDayAs: reminder.firstDay),
                       hour < reminder.hour {
                        return nil
                    }

                    guard let scheduled = calendar.date(
                        bySettingHour: hour,
                        minute: reminder.minute,
                        second: 0,
                        of: startOfDay
                    ),
                    calendar.isDate(scheduled, inSameDayAs: day) else {
                        return nil
                    }

                    let doseID = Dose.makeID(
                        reminderID: reminder.id,
                        on: day,
                        hour: hour,
                        minute: reminder.minute,
                        calendar: calendar
                    )
                    return Dose(
                        id: doseID,
                        reminder: reminder,
                        scheduled: scheduled,
                        taken: records[doseID]?.taken
                    )
                }
            }
            .sorted { lhs, rhs in
                if lhs.scheduled != rhs.scheduled {
                    return lhs.scheduled < rhs.scheduled
                }
                return lhs.reminder.id.uuidString < rhs.reminder.id.uuidString
            }
    }

    func featured(
        at now: Date,
        keepingRecorded id: String? = nil,
        calendar: Calendar = .current
    ) -> Dose? {
        let today = doses(on: now, calendar: calendar)

        if let id,
           let confirmed = today.first(where: { $0.id == id && $0.isRecorded }) {
            return confirmed
        }

        if let nextDue = today.first(where: { $0.isDue(at: now) }) {
            return nextDue
        }

        if let latestRecorded = today
            .filter(\.isRecorded)
            .max(by: { ($0.taken ?? .distantPast) < ($1.taken ?? .distantPast) }) {
            return latestRecorded
        }

        return today.first
    }

    var sortedHistory: [DoseRecord] {
        records.values.sorted { $0.taken > $1.taken }
    }

    var activeAlertCount: Int {
        reminders
            .filter(\.alerts)
            .reduce(0) { $0 + $1.scheduledHours.count }
    }

    func latestRecordToday(for reminder: Reminder, at now: Date = .now, calendar: Calendar = .current) -> DoseRecord? {
        records.values
            .filter { $0.reminderID == reminder.id && calendar.isDate($0.taken, inSameDayAs: now) }
            .max { $0.taken < $1.taken }
    }
}
