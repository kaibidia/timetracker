import SwiftUI
import TimeFlowCore

/// One period on the daily timeline.
///
/// The rail reads top-down: a marker, then a connector line dropping to the
/// next marker. The **current** (open) activity is always the topmost row —
/// its marker is a hollow orange ring with nothing above it (the timeline
/// begins here), and the line *below* it is a pale orange (the still-forming
/// live segment). Completed activities use a filled orange dot, connected by
/// the same orange at full strength. All connectors are the same width.
///
/// When `scaledHeight` is supplied, the connector is drawn at exactly that
/// height so the vertical distance between two timestamp nodes reflects the
/// interval's duration (see `TimelineScale`). Short segments switch to a
/// compact single-line label so the row never has to grow just to fit its
/// text. When `scaledHeight` is nil the row keeps its original compact layout.
///
/// Visual only — ordering, timestamps, durations, and transitions are unchanged.
struct TimelineRow: View {
    let segment: DaySegment
    let now: Date
    /// This row is the live/open activity (topmost).
    let isCurrent: Bool
    /// This row is the last one shown.
    let isLast: Bool
    /// Duration-scaled connector height, or nil for the original layout.
    var scaledHeight: CGFloat? = nil

    private let markerDiameter: CGFloat = 11

    private var scaled: Bool { scaledHeight != nil }

    private var isCompact: Bool {
        guard let scaledHeight else { return false }
        return scaledHeight < CGFloat(TimelineScale.compactHeightThreshold)
    }

    private var endLabel: String {
        if segment.isOpen { return "NOW" }
        if segment.continuesIntoNextDay { return "\(Clock.time(segment.displayEnd)) →" }
        return Clock.time(segment.displayEnd)
    }

    private var startLabel: String {
        segment.continuesFromPreviousDay ? "→ \(Clock.time(segment.displayStart))" : Clock.time(segment.displayStart)
    }

    private var name: String { segment.activityName ?? "Unclassified" }
    private var nameColor: Color { segment.activityName == nil ? AutumnTheme.secondaryText : AutumnTheme.primaryText }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            rail
            content
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if !scaled {
            originalContent
        } else if isCompact {
            compactContent
        } else {
            spaciousContent
        }
    }

    private var originalContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            timesRow(.subheadline)
            Text(name)
                .font(.body.weight(.semibold))
                .foregroundStyle(nameColor)
            Text(DurationFormat.short(segment.displayDuration))
                .font(.footnote)
                .foregroundStyle(AutumnTheme.secondaryText)
        }
        .padding(.bottom, 18)
    }

    private var spaciousContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            timesRow(.subheadline)
            HStack(spacing: 7) {
                activityIcon
                Text(name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(nameColor)
            }
            Text(DurationFormat.short(segment.displayDuration))
                .font(.footnote)
                .foregroundStyle(AutumnTheme.secondaryText)
        }
        .padding(.bottom, 6)
    }

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            timesRow(.caption)
            HStack(spacing: 6) {
                activityIcon
                Text(name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(nameColor)
                Text("· \(DurationFormat.short(segment.displayDuration))")
                    .font(.footnote)
                    .foregroundStyle(AutumnTheme.secondaryText)
            }
            .lineLimit(1)
        }
        .padding(.bottom, 4)
    }

    private func timesRow(_ font: Font) -> some View {
        HStack {
            Text(startLabel)
            Spacer(minLength: 12)
            Text(endLabel)
        }
        .font(font.weight(.medium))
        .foregroundStyle(AutumnTheme.secondaryText)
        .monospacedDigit()
    }

    @ViewBuilder
    private var activityIcon: some View {
        if let icon = segment.activityIcon {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(segment.activityColorHex.map { Color(hex: $0) } ?? AutumnTheme.accent)
        }
    }

    // MARK: - Rail

    private var rail: some View {
        VStack(spacing: 0) {
            marker()
                .padding(.top, 3)

            if let scaledHeight {
                connector.frame(height: scaledHeight)
                if isLast {
                    marker(forceFilled: true)
                }
            } else if !isLast {
                connector.frame(maxHeight: .infinity)
            }
        }
        .frame(width: 12)
    }

    private var connector: some View {
        Rectangle()
            .fill(AutumnTheme.accent.opacity(isCurrent ? 0.25 : 1.0))
            .frame(width: 2.5)
    }

    @ViewBuilder
    private func marker(forceFilled: Bool = false) -> some View {
        if isCurrent && !forceFilled {
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
