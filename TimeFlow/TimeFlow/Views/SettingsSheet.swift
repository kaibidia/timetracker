import SwiftUI

/// The app's settings. Stage 1 has a single option; more sections will land as
/// later stages add features.
struct SettingsSheet: View {
    @AppStorage(AppSettings.scaleTimelineByDuration)
    private var scaleByDuration = AppSettings.scaleTimelineByDurationDefault

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Scale intervals by duration", isOn: $scaleByDuration)
                } header: {
                    Text("Timeline")
                } footer: {
                    Text("Show longer activities with more timeline space.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
