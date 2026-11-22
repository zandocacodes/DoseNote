import SwiftUI

struct DoseCard: View {
    let dose: Dose
    let now: Date

    @ScaledMetric(relativeTo: .largeTitle) private var timeSize: CGFloat = 42

    private var isDue: Bool {
        dose.isDue(at: now)
    }

    private var statusTitle: String {
        if dose.isRecorded {
            return "Dose recorded"
        }
        return isDue ? "Dose due" : "Scheduled"
    }

    private var statusIcon: String {
        dose.isRecorded ? "checkmark.circle.fill" : "clock"
    }

    private var cardBackground: Color {
        if dose.isRecorded {
            return Color("Forest")
        }
        return isDue ? Color("Due") : Color("Mint")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(statusTitle, systemImage: statusIcon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(dose.isRecorded ? Color("Mint") : Color("Ink"))

            VStack(alignment: .leading, spacing: 2) {
                if dose.isRecorded {
                    Text("Taken at")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("White"))
                }

                Text((dose.taken ?? dose.scheduled).formatted(date: .omitted, time: .shortened))
                    .font(.system(size: timeSize, weight: .bold))
                    .monospacedDigit()
            }
            .padding(.vertical, 6)

            Text(dose.reminder.name)
                .font(.title2.bold())

            Text(footerText)
                .font(.subheadline)
                .foregroundStyle(dose.isRecorded ? Color("Mint") : Color("Ink").opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 225, alignment: .leading)
        .foregroundStyle(dose.isRecorded ? Color("White") : Color("Ink"))
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var footerText: String {
        let scheduledTime = dose.scheduled.formatted(date: .omitted, time: .shortened)
        if dose.isRecorded {
            return "Scheduled for \(scheduledTime)"
        }
        return "Scheduled for \(scheduledTime) · \(dose.reminder.frequencyDescription())"
    }
}

#Preview("Due") {
    let schedule = SampleData.sampleSchedule()
    let now = Calendar.current.date(bySettingHour: 8, minute: 12, second: 0, of: .now) ?? .now
    if let dose = schedule.featured(at: now) {
        DoseCard(dose: dose, now: now)
            .padding(24)
            .background(Color("Paper"))
    }
}

#Preview("Recorded") {
    let schedule = SampleData.sampleSchedule(markMorningTaken: true)
    let now = Calendar.current.date(bySettingHour: 8, minute: 12, second: 0, of: .now) ?? .now
    if let dose = schedule.featured(at: now) {
        DoseCard(dose: dose, now: now)
            .padding(24)
            .background(Color("Paper"))
    }
}
