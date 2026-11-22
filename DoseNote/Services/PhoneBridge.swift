import Foundation
import WatchConnectivity

final class PhoneBridge: NSObject, WCSessionDelegate {
    weak var store: ReminderStore?

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    @MainActor
    private func makePayload() -> [String: Any] {
        guard let store else { return [:] }
        let snapshot = WatchSnapshot(schedule: store.schedule)
        guard let data = try? JSONEncoder().encode(snapshot) else { return [:] }
        return ["snapshot": data]
    }

    @MainActor
    func publish() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated,
              WCSession.default.isWatchAppInstalled else {
            return
        }
        try? WCSession.default.updateApplicationContext(makePayload())
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            publish()
        }
    }

    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            publish()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            var ok = true
            if let doseID = message["dose"] as? String {
                ok = false
                if let store,
                   let dose = store.schedule.doses(on: .now).first(where: { $0.id == doseID }),
                   let taken = message["taken"] as? Bool {
                    ok = store.record(dose, taken: taken)
                }
            }

            var reply = makePayload()
            reply["ok"] = ok
            replyHandler(reply)
        }
    }
}
