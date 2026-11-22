import Combine
import Foundation
import WatchConnectivity

@MainActor
final class WatchStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var snapshot: WatchSnapshot?
    @Published var confirmedDoseID: String?
    @Published var isReachable = false
    @Published var isBusy = false
    @Published var issue: String?

    init(previewSnapshot: WatchSnapshot? = nil) {
        self.snapshot = previewSnapshot
        super.init()

        if previewSnapshot == nil, WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private func accept(_ payload: [String: Any]) {
        guard let data = payload["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else {
            return
        }
        snapshot = decoded
    }

    func refresh() {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        isReachable = session.isReachable
        accept(session.receivedApplicationContext)
        if isReachable {
            send(["refresh": true])
        }
    }

    func toggleRecord(for dose: Dose) {
        guard !isBusy else { return }
        isBusy = true
        send([
            "dose": dose.id,
            "taken": !dose.isRecorded
        ])
    }

    private func send(_ message: [String: Any]) {
        let isAction = message["dose"] != nil
        let targetDoseID = message["dose"] as? String
        let markingTaken = message["taken"] as? Bool ?? false

        WCSession.default.sendMessage(
            message,
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    guard let self else { return }
                    self.accept(reply)
                    if isAction {
                        self.isBusy = false
                        if reply["ok"] as? Bool == true {
                            self.issue = nil
                            self.confirmedDoseID = markingTaken ? targetDoseID : nil
                        } else {
                            self.issue = "Couldn’t update this dose. Check your iPhone."
                        }
                    }
                }
            },
            errorHandler: { [weak self] _ in
                Task { @MainActor in
                    guard let self else { return }
                    if isAction {
                        self.isBusy = false
                        self.issue = "Couldn’t confirm the change. Check your iPhone and retry."
                    }
                }
            }
        )
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            refresh()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            refresh()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            accept(applicationContext)
        }
    }
}
