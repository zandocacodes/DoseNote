import Foundation

enum SampleData {
    static let losartanID = UUID(uuidString: "A1000000-0000-0000-0000-000000000001")!
    static let metforminID = UUID(uuidString: "A1000000-0000-0000-0000-000000000002")!
    static let vitaminD3ID = UUID(uuidString: "A1000000-0000-0000-0000-000000000003")!

    static func sampleSchedule(
        reference: Date = .now,
        markMorningTaken: Bool = false,
        calendar: Calendar = .current
    ) -> Schedule {
        let start = calendar.date(byAdding: .day, value: -7, to: reference) ?? reference

        let losartan = Reminder(
            id: losartanID,
            name: "Losartan",
            hour: 8,
            minute: 0,
            frequency: .daily,
            firstDay: start,
            alerts: true
        )

        let metformin = Reminder(
            id: metforminID,
            name: "Metformin",
            hour: 14,
            minute: 0,
            frequency: .twice,
            firstDay: start,
            alerts: true
        )

        let vitaminD3 = Reminder(
            id: vitaminD3ID,
            name: "Vitamin D3",
            hour: 20,
            minute: 0,
            frequency: .weekly,
            firstDay: start,
            alerts: false,
            weekday: calendar.component(.weekday, from: reference)
        )

        var schedule = Schedule(reminders: [losartan, metformin, vitaminD3])

        if markMorningTaken,
           let morningDose = schedule.doses(on: reference, calendar: calendar)
            .first(where: { $0.reminder.id == losartanID }) {
            let takenAt = calendar.date(byAdding: .minute, value: 12, to: morningDose.scheduled) ?? reference
            schedule.records[morningDose.id] = DoseRecord(
                id: morningDose.id,
                reminderID: losartan.id,
                medicationName: losartan.name,
                scheduled: morningDose.scheduled,
                taken: takenAt
            )
        }

        return schedule
    }

    @MainActor
    static func previewStore(markMorningTaken: Bool = false) -> ReminderStore {
        ReminderStore(
            schedule: sampleSchedule(markMorningTaken: markMorningTaken),
            persistsToDisk: false
        )
    }

    @MainActor
    static func emptyPreviewStore() -> ReminderStore {
        ReminderStore(schedule: Schedule(), persistsToDisk: false)
    }
}
