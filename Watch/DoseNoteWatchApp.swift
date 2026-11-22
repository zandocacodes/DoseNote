import SwiftUI

@main
struct DoseNoteWatchApp: App {
    @StateObject private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchTodayView(store: store)
            }
        }
    }
}
