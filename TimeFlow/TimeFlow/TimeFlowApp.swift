import SwiftUI
import SwiftData
import TimeFlowCore

@main
struct TimeFlowApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try TimeFlowSchema.makeContainer()
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
///
/// The palette follows local sunrise / sunset via `AppearanceModel`, refreshed
/// each minute and whenever the app becomes active.
private struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: TimelineStore?
    @State private var appearance = AppearanceModel()

    private let tick = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AutumnTheme.background.ignoresSafeArea()
            if let store {
                TodayView()
                    .environment(store)
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        .task {
            guard store == nil else { return }
            let store = TimelineStore(context: modelContext)
            store.seedDefaultActivitiesIfNeeded()
            self.store = store
        }
        .onReceive(tick) { _ in appearance.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { appearance.refresh() }
        }
    }
}
