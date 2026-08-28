import SwiftUI
import SwiftData
import TimeTrackerCore

@main
struct TimeTrackerApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try TimeTrackerSchema.makeContainer()
        } catch {
            fatalError("Could not create the SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .tint(AutumnTheme.accent)
        }
    }
}

/// Builds the `TimelineStore` from the container's main context once the view
/// hierarchy exists, avoiding main-actor gymnastics in `App.init`.
private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: TimelineStore?

    var body: some View {
        ZStack {
            AutumnTheme.background.ignoresSafeArea()
            if let store {
                TodayView()
                    .environment(store)
            }
        }
        .task {
            guard store == nil else { return }
            let store = TimelineStore(context: modelContext)
            store.seedDefaultActivitiesIfNeeded()
            self.store = store
        }
    }
}
