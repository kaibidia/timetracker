import SwiftUI

/// Lightweight, briefly-shown affordance to reverse the latest capture.
struct UndoPill: View {
    var onUndo: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("Transition recorded")
                .font(.subheadline)
                .foregroundStyle(AutumnTheme.primaryText)
            Button("Undo", action: onUndo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AutumnTheme.accent)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            Capsule().fill(AutumnTheme.surfaceRaised)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
        )
    }
}
