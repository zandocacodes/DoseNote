import SwiftUI

@main
struct DoseNoteApp: App {
    @StateObject private var store = ReminderStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environmentObject(store)
                .alert(
                    "DoseNote",
                    isPresented: Binding(
                        get: { store.issue != nil },
                        set: { isPresented in
                            if !isPresented {
                                store.issue = nil
                            }
                        }
                    )
                ) {
                    Button("OK") {
                        store.issue = nil
                    }
                } message: {
                    Text(store.issue ?? "")
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        store.refreshSideEffects()
                    }
                }
        }
    }
}
