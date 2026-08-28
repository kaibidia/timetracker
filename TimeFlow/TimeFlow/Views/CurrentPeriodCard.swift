import SwiftUI
import TimeFlowCore

/// The prominent "what am I doing right now" summary. Duration updates at
/// minute resolution (driven by the parent `TimelineView`).
struct CurrentPeriodCard: View {
    let period: Period
    let now: Date
    var onTapLabel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onTapLabel) {
                HStack(spacing: 8) {
                    if let activity = period.activity {
                        Image(systemName: activity.iconSystemName)
                            .foregroundStyle(activity.color)
                        Text(activity.name.uppercased())
                            .foregroundStyle(AutumnTheme.primaryText)
                    } else {
                        Text("UNCLASSIFIED")
                            .foregroundStyle(AutumnTheme.secondaryText)
                    }
                }
                .font(.headline.weight(.semibold))
                .tracking(1.2)
            }
            .buttonStyle(.plain)

            Text(DurationFormat.short(period.duration(asOf: now)))
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(AutumnTheme.primaryText)
                .monospacedDigit()
                .contentTransition(.numericText())

            Text("since \(Clock.time(period.startTime))")
                .font(.subheadline)
                .foregroundStyle(AutumnTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
