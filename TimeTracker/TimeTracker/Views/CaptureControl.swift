import SwiftUI

/// The main capture control.
///
/// Sequence: REST → PRESS → FILL (centre-out) → COMMIT → RIPPLE → REST.
///
/// - Touch-down captures a candidate timestamp immediately and starts a
///   ~`holdDuration` fill that grows from the centre.
/// - Releasing, or dragging outside the control, before the fill completes
///   cancels: the fill collapses and the candidate timestamp is discarded.
/// - On completion the control commits using the **touch-down** timestamp,
///   fires one crisp haptic and emits a soft ripple. No checkmark.
struct CaptureControl: View {
    /// Hold-to-confirm duration. Kept as a single tunable constant.
    static let holdDuration: Duration = .milliseconds(500)

    var isTracking: Bool
    var onCommit: (Date) -> Void

    private enum Phase { case rest, pressing, committing }

    @State private var phase: Phase = .rest
    @State private var fill: CGFloat = 0
    @State private var candidateTimestamp: Date?
    @State private var holdTask: Task<Void, Never>?
    @State private var rippleScale: CGFloat = 0.9
    @State private var rippleOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let diameter: CGFloat = 208
    private let cancelSlop: CGFloat = 40

    private var holdSeconds: Double {
        Double(CaptureControl.holdDuration.components.seconds)
            + Double(CaptureControl.holdDuration.components.attoseconds) / 1e18
    }

    var body: some View {
        VStack(spacing: 18) {
            disc
            Text(isTracking ? "ACTIVITY CHANGED" : "START TRACKING")
                .font(.footnote.weight(.semibold))
                .tracking(1.6)
                .foregroundStyle(AutumnTheme.secondaryText)
                .animation(nil, value: isTracking)
        }
    }

    private var disc: some View {
        ZStack {
            // Outward ripple on commit.
            Circle()
                .stroke(AutumnTheme.accent.opacity(0.5), lineWidth: 2)
                .frame(width: diameter, height: diameter)
                .scaleEffect(rippleScale)
                .opacity(rippleOpacity)

            // Soft resting disc.
            Circle()
                .fill(AutumnTheme.captureRim)
                .overlay(Circle().strokeBorder(AutumnTheme.accent.opacity(0.16), lineWidth: 1))
                .shadow(color: AutumnTheme.accent.opacity(0.16), radius: 18, y: 8)

            // Centre-out fill during the hold.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AutumnTheme.captureCore, AutumnTheme.captureCore.opacity(0.85)],
                        center: .center,
                        startRadius: 2,
                        endRadius: diameter * 0.6
                    )
                )
                .scaleEffect(max(0.0001, fill))
                .opacity(fill > 0 ? 1 : 0)

            // Small persistent core so the resting state isn't empty.
            Circle()
                .fill(AutumnTheme.captureCore)
                .frame(width: 66, height: 66)
                .opacity(fill > 0.15 ? 0 : 1)
                .overlay(
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 9, height: 9)
                        .opacity(fill > 0.15 ? 0 : 1)
                )
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .scaleEffect(phase == .pressing ? 0.965 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: phase)
        .gesture(pressGesture)
        .accessibilityElement()
        .accessibilityLabel(isTracking ? "Activity changed" : "Start tracking")
        .accessibilityHint("Press and hold briefly to confirm")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Gesture

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                switch phase {
                case .rest:
                    begin()
                case .pressing:
                    if distanceFromCentre(value.location) > diameter / 2 + cancelSlop {
                        cancel()
                    }
                case .committing:
                    break
                }
            }
            .onEnded { _ in
                if phase == .pressing { cancel() }
            }
    }

    private func distanceFromCentre(_ point: CGPoint) -> CGFloat {
        let centre = CGPoint(x: diameter / 2, y: diameter / 2)
        return hypot(point.x - centre.x, point.y - centre.y)
    }

    // MARK: - Phases

    private func begin() {
        candidateTimestamp = .now
        phase = .pressing
        Haptics.prepareCapture()

        withAnimation(.linear(duration: reduceMotion ? 0 : holdSeconds)) {
            fill = 1
        }

        holdTask?.cancel()
        holdTask = Task { @MainActor in
            try? await Task.sleep(for: CaptureControl.holdDuration)
            guard !Task.isCancelled, phase == .pressing,
                  let timestamp = candidateTimestamp else { return }
            commit(timestamp)
        }
    }

    private func cancel() {
        holdTask?.cancel()
        holdTask = nil
        candidateTimestamp = nil
        phase = .rest
        withAnimation(.easeOut(duration: 0.22)) { fill = 0 }
    }

    private func commit(_ timestamp: Date) {
        phase = .committing
        candidateTimestamp = nil
        holdTask = nil

        Haptics.captureConfirm()
        onCommit(timestamp)
        emitRipple()

        withAnimation(.easeOut(duration: 0.32)) { fill = 0 }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(340))
            phase = .rest
        }
    }

    private func emitRipple() {
        guard !reduceMotion else { return }
        rippleScale = 0.9
        rippleOpacity = 0.55
        withAnimation(.easeOut(duration: 0.6)) {
            rippleScale = 1.7
            rippleOpacity = 0
        }
    }
}
