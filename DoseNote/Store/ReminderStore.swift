import Combine
import Foundation
import UserNotifications

@MainActor
final class ReminderStore: ObservableObject {
    @Published private(set) var schedule: Schedule
    @Published var issue: String?
    @Published var permission: UNAuthorizationStatus = .notDetermined

    private let scheduler = NotificationScheduler()
    private let bridge = PhoneBridge()
    private let persistsToDisk: Bool
    private var revision = 0
    private var isSyncingAlerts = false

    init(schedule: Schedule? = nil, persistsToDisk: Bool = true) {
        self.persistsToDisk = persistsToDisk
        self.schedule = schedule ?? Schedule()

        if persistsToDisk {
            loadFromDisk()
            bridge.store = self
            bridge.start()
            refreshSideEffects()
        }
    }

    private func storageURL() throws -> URL {
        let supportDir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return supportDir.appendingPathComponent("schedule.json")
    }

    private func loadFromDisk() {
        do {
            let fileURL = try storageURL()
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                schedule = Schedule()
                return
            }
            let data = try Data(contentsOf: fileURL)
            schedule = try JSONDecoder().decode(Schedule.self, from: data)
        } catch {
            issue = "Couldn’t open your saved reminders. Please try again."
        }
    }

    @discardableResult
    private func commit(_ next: Schedule) -> Bool {
        if persistsToDisk {
            do {
                let data = try JSONEncoder().encode(next)
                try data.write(to: storageURL(), options: [.atomic, .completeFileProtection])
            } catch {
                issue = "Couldn’t save this change. Please try again."
                return false
            }
        }

        schedule = next
        if persistsToDisk {
            refreshSideEffects()
        }
        return true
    }

    @discardableResult
    func save(_ reminder: Reminder) -> Bool {
        var next = schedule
        next.reminders.removeAll { $0.id == reminder.id }
        next.reminders.append(reminder)

        guard next.activeAlertCount <= NotificationScheduler.maxLocalAlerts else {
            issue = "Too many active alert times. Pause another reminder and try again."
            return false
        }

        return commit(next)
    }

    func delete(_ reminder: Reminder) {
        var next = schedule
        next.reminders.removeAll { $0.id == reminder.id }
        commit(next)
    }

    @discardableResult
    func record(_ dose: Dose, taken: Bool, at now: Date = .now) -> Bool {
        guard let current = schedule.doses(on: now).first(where: { $0.id == dose.id }),
              current.scheduled <= now else {
            return false
        }

        if current.isRecorded == taken {
            return true
        }

        var next = schedule
        if taken {
            next.records[dose.id] = DoseRecord(
                id: dose.id,
                reminderID: current.reminder.id,
                medicationName: current.reminder.name,
                scheduled: current.scheduled,
                taken: now
            )
        } else {
            next.records.removeValue(forKey: dose.id)
        }

        return commit(next)
    }

    func requestAlerts() async {
        guard persistsToDisk else { return }
        do {
            permission = try await scheduler.requestPermissionIfNeeded()
        } catch {
            issue = "Couldn’t request notification permission."
        }
        refreshSideEffects()
    }

    func refreshSideEffects() {
        guard persistsToDisk else { return }
        revision += 1
        bridge.publish()

        guard !isSyncingAlerts else { return }
        isSyncingAlerts = true

        Task {
            defer { isSyncingAlerts = false }
            while true {
                let version = revision
                do {
                    permission = try await scheduler.sync(reminders: schedule.reminders) { [weak self] in
                        self?.revision == version
                    }
                } catch {
                    issue = "Some alerts couldn’t be scheduled. Check notification settings."
                }
                if version == revision {
                    break
                }
            }
        }
    }
}
