import XCTest
@testable import DoseNote

final class ScheduleTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int, minute: Int = 0) -> Date {
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return calendar.date(from: components)!
    }

    func testDailyReminderDoesNotAppearBeforeFirstDay() {
        let firstDay = makeDate(year: 2026, month: 11, day: 20, hour: 8)
        let reminder = Reminder(
            name: "Losartan",
            hour: 8,
            minute: 0,
            frequency: .daily,
            firstDay: firstDay,
            alerts: true
        )
        let schedule = Schedule(reminders: [reminder])

        let previousDay = makeDate(year: 2026, month: 11, day: 19, hour: 10)
        XCTAssertTrue(schedule.doses(on: previousDay, calendar: calendar).isEmpty)

        let sameDay = makeDate(year: 2026, month: 11, day: 20, hour: 10)
        let doses = schedule.doses(on: sameDay, calendar: calendar)
        XCTAssertEqual(doses.count, 1)
        XCTAssertEqual(doses.first?.scheduled, firstDay)
    }

    func testTwiceDailySchedulesBothHoursAndSkipsEarlierSlotOnFirstDay() {
        let firstDay = makeDate(year: 2026, month: 11, day: 20, hour: 14)
        let reminder = Reminder(
            name: "Metformin",
            hour: 14,
            minute: 0,
            frequency: .twice,
            firstDay: firstDay,
            alerts: true
        )
        let schedule = Schedule(reminders: [reminder])

        // On first day starting at 14:00, the 02:00 slot is skipped.
        let firstDayDoses = schedule.doses(on: firstDay, calendar: calendar)
        XCTAssertEqual(firstDayDoses.map { calendar.component(.hour, from: $0.scheduled) }, [14])

        // On the following day, both 02:00 and 14:00 are generated in order.
        let nextDay = makeDate(year: 2026, month: 11, day: 21, hour: 9)
        let nextDayDoses = schedule.doses(on: nextDay, calendar: calendar)
        XCTAssertEqual(nextDayDoses.map { calendar.component(.hour, from: $0.scheduled) }, [2, 14])
    }

    func testWeeklyReminderOnlyAppearsOnConfiguredWeekday() {
        let friday = makeDate(year: 2026, month: 11, day: 20, hour: 20)
        let fridayWeekday = calendar.component(.weekday, from: friday)

        let reminder = Reminder(
            name: "Vitamin D3",
            hour: 20,
            minute: 0,
            frequency: .weekly,
            firstDay: friday,
            alerts: true,
            weekday: fridayWeekday
        )
        let schedule = Schedule(reminders: [reminder])

        let saturday = makeDate(year: 2026, month: 11, day: 21, hour: 20)
        let nextFriday = makeDate(year: 2026, month: 11, day: 27, hour: 20)

        XCTAssertEqual(schedule.doses(on: friday, calendar: calendar).count, 1)
        XCTAssertTrue(schedule.doses(on: saturday, calendar: calendar).isEmpty)
        XCTAssertEqual(schedule.doses(on: nextFriday, calendar: calendar).count, 1)
    }

    func testFeaturedPrioritizesDueThenKeptRecordedThenUpcoming() {
        let day = makeDate(year: 2026, month: 11, day: 20, hour: 0)
        let morning = Reminder(
            name: "Losartan",
            hour: 8,
            minute: 0,
            frequency: .daily,
            firstDay: day,
            alerts: true
        )
        let afternoon = Reminder(
            name: "Metformin",
            hour: 14,
            minute: 0,
            frequency: .daily,
            firstDay: day,
            alerts: true
        )
        var schedule = Schedule(reminders: [morning, afternoon])

        // At 07:00 nothing is due yet -> returns first upcoming (08:00).
        let beforeFirst = makeDate(year: 2026, month: 11, day: 20, hour: 7)
        XCTAssertEqual(schedule.featured(at: beforeFirst, calendar: calendar)?.reminder.name, "Losartan")

        // At 08:12 morning is due.
        let atMorning = makeDate(year: 2026, month: 11, day: 20, hour: 8, minute: 12)
        let dueDose = try! XCTUnwrap(schedule.featured(at: atMorning, calendar: calendar))
        XCTAssertTrue(dueDose.isDue(at: atMorning))

        // After recording morning at 08:12, keepingRecorded keeps it visible.
        schedule.records[dueDose.id] = DoseRecord(
            id: dueDose.id,
            reminderID: morning.id,
            medicationName: morning.name,
            scheduled: dueDose.scheduled,
            taken: atMorning
        )
        let kept = schedule.featured(at: atMorning, keepingRecorded: dueDose.id, calendar: calendar)
        XCTAssertEqual(kept?.id, dueDose.id)
        XCTAssertTrue(kept?.isRecorded == true)

        // At 14:05 afternoon becomes due when keepingRecorded is cleared.
        let atAfternoon = makeDate(year: 2026, month: 11, day: 20, hour: 14, minute: 5)
        XCTAssertEqual(schedule.featured(at: atAfternoon, calendar: calendar)?.reminder.name, "Metformin")
    }

    func testDoseIDIsCalendarComponentBasedAndStableAcrossTimeZones() {
        let reminderID = UUID()
        let utcDay = makeDate(year: 2026, month: 11, day: 20, hour: 8)

        var brazilCalendar = Calendar(identifier: .gregorian)
        brazilCalendar.timeZone = TimeZone(secondsFromGMT: -3 * 3600)!
        let brazilDay = brazilCalendar.date(
            from: DateComponents(year: 2026, month: 11, day: 20, hour: 8)
        )!

        let utcID = Dose.makeID(reminderID: reminderID, on: utcDay, hour: 8, minute: 0, calendar: calendar)
        let brazilID = Dose.makeID(reminderID: reminderID, on: brazilDay, hour: 8, minute: 0, calendar: brazilCalendar)

        XCTAssertEqual(utcID, brazilID)
        XCTAssertTrue(utcID.hasSuffix("-2026-11-20-08-00"))
    }

    func testActiveAlertCountRespectsTwiceDailyAndPausedReminders() {
        let now = makeDate(year: 2026, month: 11, day: 20, hour: 8)
        let schedule = Schedule(reminders: [
            Reminder(name: "Losartan", hour: 8, minute: 0, frequency: .daily, firstDay: now, alerts: true),
            Reminder(name: "Metformin", hour: 14, minute: 0, frequency: .twice, firstDay: now, alerts: true),
            Reminder(name: "Vitamin D3", hour: 20, minute: 0, frequency: .weekly, firstDay: now, alerts: false)
        ])

        XCTAssertEqual(schedule.activeAlertCount, 3)
    }

    func testScheduleCodableRoundTrip() throws {
        let now = makeDate(year: 2026, month: 11, day: 20, hour: 8, minute: 12)
        let reminder = Reminder(
            name: "Losartan",
            hour: 8,
            minute: 0,
            frequency: .daily,
            firstDay: now,
            alerts: true
        )
        var original = Schedule(reminders: [reminder])
        let dose = try XCTUnwrap(original.doses(on: now, calendar: calendar).first)
        original.records[dose.id] = DoseRecord(
            id: dose.id,
            reminderID: reminder.id,
            medicationName: reminder.name,
            scheduled: dose.scheduled,
            taken: now
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Schedule.self, from: data)
        XCTAssertEqual(decoded, original)
    }
}
