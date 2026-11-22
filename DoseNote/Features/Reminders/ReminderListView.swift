import SwiftUI

struct ReminderListView: View {
    @EnvironmentObject private var store: ReminderStore
    @State private var isAddingReminder = false

    private var sortedReminders: [Reminder] {
        store.schedule.reminders.sorted { lhs, rhs in
            if lhs.hour != rhs.hour {
                return lhs.hour < rhs.hour
            }
            if lhs.minute != rhs.minute {
                return lhs.minute < rhs.minute
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        List {
            Group {
                PageHeading(
                    title: "My reminders",
                    subtitle: "Your medication schedule"
                )

                ForEach(sortedReminders) { reminder in
                    NavigationLink {
                        ReminderFormView(original: reminder)
                    } label: {
                        reminderRow(for: reminder)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            store.delete(reminder)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                Button("Add a reminder") {
                    isAddingReminder = true
                }
                .buttonStyle(.dosePrimary)
                .padding(.top, 8)

                if !store.schedule.sortedHistory.isEmpty {
                    Section("Dose history") {
                        ForEach(store.schedule.sortedHistory) { record in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.medicationName)
                                    .font(.headline)
                                Text("Scheduled: \(record.scheduled.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("Muted"))
                                Text("Taken: \(record.taken.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(Color("Forest"))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 6, leading: 24, bottom: 6, trailing: 24))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color("Paper").ignoresSafeArea())
        .foregroundStyle(Color("Ink"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingReminder) {
            ReminderFormView(original: nil)
        }
    }

    private func reminderRow(for reminder: Reminder) -> some View {
        let takenToday = store.schedule.latestRecordToday(for: reminder)

        return HStack(alignment: .top, spacing: 16) {
            Text(reminder.scheduledTime().formatted(date: .omitted, time: .shortened))
                .font(.headline)
                .monospacedDigit()
                .frame(minWidth: 54, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.name)
                    .font(.headline)

                Text(reminder.frequencyDescription())
                    .font(.subheadline)
                    .foregroundStyle(Color("Muted"))

                HStack(spacing: 10) {
                    Text(reminder.alerts ? "Alerts on" : "Alerts paused")
                        .font(.caption)
                        .foregroundStyle(Color("Muted"))

                    if let record = takenToday {
                        Text("✓ Taken today at \(record.taken.formatted(date: .omitted, time: .shortened))")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color("Forest"))
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ReminderListView()
    }
    .environmentObject(SampleData.previewStore(markMorningTaken: true))
}
