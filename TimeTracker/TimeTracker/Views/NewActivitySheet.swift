import SwiftUI
import TimeTrackerCore

/// Create a custom activity: name + SF Symbol + colour. No custom icon system.
struct NewActivitySheet: View {
    var onCreate: (Activity) -> Void

    @Environment(TimelineStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "star.fill"
    @State private var colorHex = AutumnTheme.activityPalette[0]

    private static let icons = [
        "star.fill", "heart.fill", "book.fill", "music.note", "paintbrush.fill",
        "leaf.fill", "cup.and.saucer.fill", "fork.knife", "figure.walk", "figure.run",
        "figure.strengthtraining.traditional", "bicycle", "car.fill", "tram.fill", "airplane",
        "house.fill", "bed.double.fill", "laptopcomputer", "phone.fill", "message.fill",
        "camera.fill", "gamecontroller.fill", "pawprint.fill", "cart.fill", "bag.fill",
        "graduationcap.fill", "pencil.and.outline", "globe", "sun.max.fill", "moon.fill"
    ]
    private let iconColumns = [GridItem(.adaptive(minimum: 46), spacing: 12)]
    private let colorColumns = [GridItem(.adaptive(minimum: 40), spacing: 12)]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Icon") {
                    LazyVGrid(columns: iconColumns, spacing: 12) {
                        ForEach(Self.icons, id: \.self) { symbol in
                            Image(systemName: symbol)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .foregroundStyle(symbol == icon ? Color(hex: colorHex) : AutumnTheme.secondaryText)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(symbol == icon ? Color(hex: colorHex).opacity(0.18) : Color.clear)
                                )
                                .onTapGesture { icon = symbol }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Colour") {
                    LazyVGrid(columns: colorColumns, spacing: 12) {
                        ForEach(AutumnTheme.activityPalette, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(AutumnTheme.primaryText, lineWidth: hex == colorHex ? 2 : 0)
                                )
                                .onTapGesture { colorHex = hex }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack(spacing: 10) {
                        Image(systemName: icon).foregroundStyle(Color(hex: colorHex))
                        Text(trimmedName.isEmpty ? "Preview" : trimmedName)
                            .foregroundStyle(AutumnTheme.primaryText)
                    }
                    .font(.headline)
                }
            }
            .navigationTitle("New activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        guard let activity = try? store.createActivity(
                            name: trimmedName, iconSystemName: icon, colorHex: colorHex
                        ) else { return }
                        onCreate(activity)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
