import SwiftUI
import TimeTrackerCore

/// One period on the daily timeline, drawn to read as a span *between two points
/// in time*: a dot at the start, a connector, and (for the open period) a hollow
/// "now" marker.
struct TimelineRow: View {
    let segment: DaySegment
    let now: Date
    let isFirst: Bool
    let isLast: Bool

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
            Circle()
                .fill(AutumnTheme.accent)
                .frame(width: 9, height: 9)
                .padding(.top, 4)
            Rectangle()
                .fill(AutumnTheme.hairline)
                .frame(width: 2)
                .frame(maxHeight: .infinity)
            if segment.isOpen {
                Circle()
                    .strokeBorder(AutumnTheme.accent, lineWidth: 2)
                    .frame(width: 11, height: 11)
            }
        }
        .frame(width: 12)
    }
}
