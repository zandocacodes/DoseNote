import SwiftUI

struct ReminderFormView: View {
    let original: Reminder?

    @EnvironmentObject private var store: ReminderStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var time: Date
    @State private var frequency: Frequency
    @State private var weekday: Int
    @State private var alerts: Bool
    @State private var validationError: String?

    init(original: Reminder?) {
        self.original = original
        _name = State(initialValue: original?.name ?? "")
        _time = State(initialValue: original?.scheduledTime() ?? .now)
        _frequency = State(initialValue: original?.frequency ?? .daily)
        _weekday = State(
            initialValue: original?.weeklyDay() ?? Calendar.current.component(.weekday, from: .now)
        )
        _alerts = State(initialValue: original?.alerts ?? true)
    }

    var body: some View {
        if original == nil {
            NavigationStack {
                formContent
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                        }
                    }
            }
        } else {
            formContent
        }
    }

    private var formContent: some View {
        DosePage {
            PageHeading(
                title: original == nil ? "New reminder" : "Edit reminder",
                subtitle: "Use the schedule on your prescription."
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Medication name")
                    .font(.headline)

                TextField("e.g. Losartan 50 mg", text: $name)
                    .doseField()
            }

            DatePicker("Scheduled time", selection: $time, displayedComponents: .hourAndMinute)
                .doseField()

            Picker("Repeat", selection: $frequency) {
                ForEach(Frequency.allCases, id: \.self) { option in
                    Text(option.label)
                        .tag(option)
                }
            }
            .doseField()

            if frequency == .weekly {
                Picker("Day of the week", selection: $weekday) {
                    ForEach(1...7, id: \.self) { day in
                        Text(Calendar.current.weekdaySymbols[day - 1])
                            .tag(day)
                    }
                }
                .doseField()
            }

            Toggle("Reminder alerts", isOn: $alerts)
                .padding(.top, 4)

            if !alerts {
                Text("Alerts paused. You can still record a dose.")
                    .font(.subheadline)
                    .foregroundStyle(Color("Muted"))
            }

            if let validationError {
                Text(validationError)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            Button(original == nil ? "Save reminder" : "Save changes") {
                saveReminder()
            }
            .buttonStyle(.dosePrimary)
            .padding(.top, 16)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveReminder() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "Enter a medication name."
            return
        }

        validationError = nil
        let calendar = Calendar.current
        let reminder = Reminder(
            id: original?.id ?? UUID(),
            name: trimmedName,
            hour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            frequency: frequency,
            firstDay: original?.firstDay ?? .now,
            alerts: alerts,
            weekday: frequency == .weekly ? weekday : nil
        )

        if store.save(reminder) {
            dismiss()
            if alerts {
                Task {
                    await store.requestAlerts()
                }
            }
        }
    }
}

#Preview("New") {
    ReminderFormView(original: nil)
        .environmentObject(SampleData.previewStore())
}

#Preview("Edit") {
    let sample = SampleData.sampleSchedule().reminders.first
    NavigationStack {
        ReminderFormView(original: sample)
    }
    .environmentObject(SampleData.previewStore())
}
