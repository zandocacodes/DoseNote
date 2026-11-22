import SwiftUI

struct WatchTodayView: View {
    @ObservedObject var store: WatchStore

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let snapshot = store.snapshot {
                        if let dose = snapshot.schedule.featured(
                            at: context.date,
                            keepingRecorded: store.confirmedDoseID
                        ) {
                            watchCard(for: dose, at: context.date, schedule: snapshot.schedule)
                        } else {
                            Text("No doses scheduled today.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Open DoseNote on your iPhone to sync your schedule.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    if !store.isReachable {
                        Text("Connect your iPhone to update doses.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let issue = store.issue {
                        Text(issue)
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("DoseNote")
        }
    }

    @ViewBuilder
    private func watchCard(for dose: Dose, at now: Date, schedule: Schedule) -> some View {
        let isRecorded = dose.isRecorded
        let isDue = dose.isDue(at: now)
        let cardColor: Color = isRecorded ? Color("Forest") : (isDue ? Color("Due") : Color("Mint"))
        let primaryText: Color = isRecorded ? Color("White") : Color("Ink")

        VStack(alignment: .leading, spacing: 6) {
            Text(dose.reminder.name)
                .font(.title3.bold())
                .lineLimit(2)

            Text(
                isRecorded
                    ? "✓ Recorded · Taken at"
                    : (isDue ? "Dose due · Scheduled for" : "Scheduled for")
            )
            .font(.caption2)
            .opacity(0.9)

            Text((dose.taken ?? dose.scheduled).formatted(date: .omitted, time: .shortened))
                .font(.system(.largeTitle, design: .default, weight: .bold))
                .monospacedDigit()

            if dose.scheduled <= now {
                Button {
                    store.toggleRecord(for: dose)
                } label: {
                    Text(isRecorded ? "Undo" : "Mark as taken")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color("Ink"))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(Color("Mint"), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!store.isReachable || store.isBusy)
                .padding(.top, 6)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(primaryText)
        .background(cardColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

        if isRecorded,
           let nextDose = schedule.featured(at: now),
           nextDose.id != dose.id,
           !nextDose.isRecorded {
            Button("View next due dose") {
                store.confirmedDoseID = nil
            }
            .font(.footnote)
            .disabled(store.isBusy)
        }
    }
}

#Preview("Due") {
    let reminder = Reminder(
        name: "Losartan",
        hour: 8,
        minute: 0,
        frequency: .daily,
        firstDay: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now,
        alerts: true
    )
    let store = WatchStore(previewSnapshot: WatchSnapshot(schedule: Schedule(reminders: [reminder])))
    store.isReachable = true
    return NavigationStack {
        WatchTodayView(store: store)
    }
}

#Preview("Recorded") {
    let start = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
    let reminder = Reminder(
        name: "Losartan",
        hour: 8,
        minute: 0,
        frequency: .daily,
        firstDay: start,
        alerts: true
    )
    var schedule = Schedule(reminders: [reminder])
    if let dose = schedule.doses(on: .now).first {
        schedule.records[dose.id] = DoseRecord(
            id: dose.id,
            reminderID: reminder.id,
            medicationName: reminder.name,
            scheduled: dose.scheduled,
            taken: .now
        )
    }
    let store = WatchStore(previewSnapshot: WatchSnapshot(schedule: schedule))
    store.isReachable = true
    return NavigationStack {
        WatchTodayView(store: store)
    }
}
