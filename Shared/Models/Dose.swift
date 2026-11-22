import Foundation

struct Dose: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let reminder: Reminder
    let scheduled: Date
    let taken: Date?

    var isRecorded: Bool {
        taken != nil
    }

    func isDue(at now: Date) -> Bool {
        !isRecorded && scheduled <= now
    }

    static func makeID(
        reminderID: UUID,
        on day: Date,
        hour: Int,
        minute: Int,
        calendar: Calendar = .current
    ) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let dayOfMonth = components.day ?? 0
        return String(
            format: "%@-%04d-%02d-%02d-%02d-%02d",
            reminderID.uuidString,
            year,
            month,
            dayOfMonth,
            hour,
            minute
        )
    }
}

struct DoseRecord: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let reminderID: UUID
    let medicationName: String
    let scheduled: Date
    let taken: Date
}
