import SwiftUI
import TimeFlowCore

/// One period on the daily timeline.
///
/// The rail reads top-down: a marker, then a connector line dropping to the
/// next marker. The **current** (open) activity is always the topmost row —
/// its marker is a hollow orange ring with nothing above it (the timeline
/// begins here), and the line *below* it is bright orange to signify the
/// activity in progress. Completed activities use a filled orange dot; the
/// lines between them are the same orange at low opacity.
///
/// Visual only — ordering, timestamps, durations, and transitions are unchanged.
struct TimelineRow: View {
    let segment: DaySegment
    let now: Date
    /// This row is the live/open activity (topmost).
    let isCurrent: Bool
    /// This row is the last one shown, so it has no connector below it.
    let isLast: Bool

    private let markerDiameter: CGFloat = 11

    private var endLabel: String {
        if segment.isOpen { return "NOW" }
        if segment.continuesIntoNextDay { return "\(Clock.time(segment.displayEnd)) →" }
        return Clock.time(segment.displayEnd)
    }

    private var startLabel: String {
        segment.continuesFromPreviousDay ? "→ \(Clock.time(segment.displayStart))" : Clock.time(segment.displayStart)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            rail
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(startLabel)
                    Spacer()
                    Text(endLabel)
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AutumnTheme.secondaryText)
                .monospacedDigit()

                Text(segment.activityName ?? "Unclassified")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(segment.activityName == nil ? AutumnTheme.secondaryText : AutumnTheme.primaryText)

                Text(DurationFormat.short(segment.displayDuration))
                    .font(.footnote)
                    .foregroundStyle(AutumnTheme.secondaryText)
            }
            .padding(.bottom, 18)
        }
    }

    private var rail: some View {
        VStack(spacing: 0) {
            marker
                .padding(.top, 3)
            if !isLast {
                Rectangle()
                    .fill(AutumnTheme.accent.opacity(isCurrent ? 1.0 : 0.25))
                    .frame(width: isCurrent ? 3 : 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 12)
    }

    @ViewBuilder
    private var marker: some View {
        if isCurrent {
            // Hollow ring — the open beginning of the live timeline.
            Circle()
                .strokeBorder(AutumnTheme.accent, lineWidth: 2)
                .frame(width: markerDiameter, height: markerDiameter)
        } else {
            Circle()
                .fill(AutumnTheme.accent)
                .frame(width: markerDiameter, height: markerDiameter)
        }
    }
}
