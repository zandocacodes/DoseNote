import Foundation
import UserNotifications

struct NotificationScheduler {
    static let maxLocalAlerts = 64
    private static let identifierPrefix = "dose."

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestPermissionIfNeeded() async throws -> UNAuthorizationStatus {
        let current = await authorizationStatus()
        guard current == .notDetermined else {
            return current
        }
        _ = try await center.requestAuthorization(options: [.alert, .sound])
        return await authorizationStatus()
    }

    func sync(
        reminders: [Reminder],
        shouldContinue: @MainActor () -> Bool
    ) async throws -> UNAuthorizationStatus {
        let status = await authorizationStatus()
        let pending = await center.pendingNotificationRequests()
        let existingIDs = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }

        var desired: [String: UNNotificationRequest] = [:]

        if status == .authorized || status == .provisional {
            for reminder in reminders where reminder.alerts {
                for hour in reminder.scheduledHours {
                    var components = DateComponents()
                    components.hour = hour
                    components.minute = reminder.minute
                    if reminder.frequency == .weekly {
                        components.weekday = reminder.weeklyDay()
                    }

                    let content = UNMutableNotificationContent()
                    content.title = "DoseNote"
                    content.body = "Scheduled reminder: \(reminder.name)"
                    content.sound = .default

                    let id = "\(Self.identifierPrefix)\(reminder.id.uuidString).\(hour)"
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                    desired[id] = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                }
            }
        }

        let staleIDs = existingIDs.filter { desired[$0] == nil }
        if !staleIDs.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: staleIDs)
        }

        for request in desired.values {
            guard await shouldContinue() else {
                break
            }
            try await center.add(request)
        }

        return status
    }
}
