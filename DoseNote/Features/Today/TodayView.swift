import SwiftUI
import UserNotifications

struct TodayView: View {
    @EnvironmentObject private var store: ReminderStore
    @Environment(\.openURL) private var openURL

    @State private var isAddingReminder = false
    @State private var recentlyRecordedDoseID: String?

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 30)) { context in
                DosePage {
                    Text("DoseNote")
                        .font(.headline)
                        .padding(.bottom, 12)

                    PageHeading(
                        title: "Today",
                        subtitle: context.date.formatted(.dateTime.weekday(.wide).month(.wide).day())
                    )

                    if let dose = store.schedule.featured(
                        at: context.date,
                        keepingRecorded: recentlyRecordedDoseID
                    ) {
                        DoseCard(dose: dose, now: context.date)

                        let upcoming = store.schedule
                            .doses(on: context.date)
                            .filter { $0.id != dose.id && !$0.isRecorded }

                        if dose.isRecorded {
                            if let nextDose = upcoming.first {
                                Text(
                                    "Up next · \(nextDose.scheduled.formatted(date: .omitted, time: .shortened)) · \(nextDose.reminder.name)"
                                )
                                .font(.body)
                                .foregroundStyle(Color("Ink"))
                                .padding(.top, 4)
                            } else {
                                Text("No more doses scheduled for today.")
                                    .font(.body)
                                    .foregroundStyle(Color("Muted"))
                                    .padding(.top, 4)
                            }
                        }

                        if dose.isRecorded {
                            Button("Undo") {
                                if store.record(dose, taken: false, at: context.date) {
                                    recentlyRecordedDoseID = nil
                                }
                            }
                            .buttonStyle(.doseSecondary)
                        } else if dose.scheduled <= context.date {
                            Button("Mark as taken") {
                                if store.record(dose, taken: true, at: context.date) {
                                    recentlyRecordedDoseID = dose.id
                                }
                            }
                            .buttonStyle(.dosePrimary)
                        }

                        if dose.isRecorded,
                           store.schedule.doses(on: context.date).contains(where: { $0.isDue(at: context.date) }) {
                            Button("View next due dose") {
                                recentlyRecordedDoseID = nil
                            }
                            .font(.headline)
                            .frame(minHeight: 44)
                        }

                        NavigationLink("View my reminders") {
                            ReminderListView()
                        }
                        .buttonStyle(.doseSecondary)

                        Button {
                            isAddingReminder = true
                        } label: {
                            Label("Add a reminder", systemImage: "plus")
                                .font(.headline)
                        }
                        .frame(minHeight: 44)
                        .padding(.top, 4)
                    } else if store.schedule.reminders.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("No reminders yet")
                                .font(.title2.bold())
                            Text("Add your first medication to get started.")
                                .foregroundStyle(Color("Muted"))
                        }
                        .padding(.bottom, 12)

                        Button("Add my first reminder") {
                            isAddingReminder = true
                        }
                        .buttonStyle(.dosePrimary)
                    } else {
                        Text("No doses scheduled today")
                            .font(.title2.bold())

                        NavigationLink("View my reminders") {
                            ReminderListView()
                        }
                        .buttonStyle(.doseSecondary)

                        Button {
                            isAddingReminder = true
                        } label: {
                            Label("Add a reminder", systemImage: "plus")
                                .font(.headline)
                        }
                        .frame(minHeight: 44)
                    }

                    if store.permission == .denied,
                       store.schedule.reminders.contains(where: \.alerts) {
                        notificationWarningBanner
                    }
                }
            }
            .navigationTitle("Today")
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isAddingReminder) {
                ReminderFormView(original: nil)
            }
        }
        .tint(Color("Forest"))
    }

    private var notificationWarningBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notifications are off in iPhone Settings.", systemImage: "bell.slash")
                .font(.subheadline.weight(.semibold))
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    openURL(url)
                }
            }
            .font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("Surface"), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, 8)
    }
}

#Preview("Due") {
    TodayView()
        .environmentObject(SampleData.previewStore(markMorningTaken: false))
}

#Preview("Recorded") {
    TodayView()
        .environmentObject(SampleData.previewStore(markMorningTaken: true))
}

#Preview("First Visit") {
    TodayView()
        .environmentObject(SampleData.emptyPreviewStore())
}
