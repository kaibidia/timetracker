import Foundation
import SwiftData

public enum TimeFlowSchema {
    public static let models: [any PersistentModel.Type] = [Activity.self, Period.self]

    /// A persistent container backed by the app's default store location.
    public static func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: false)]
        )
    }

    /// An in-memory container for tests and SwiftUI previews.
    public static func makeInMemoryContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(models),
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }
}
