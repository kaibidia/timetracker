import SwiftUI
import UIKit
import TimeFlowCore

// MARK: - Haptics

enum Haptics {
    /// One crisp confirmation for a committed capture.
    static func captureConfirm() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }

    static func prepareCapture() {
        UIImpactFeedbackGenerator(style: .rigid).prepare()
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Formatting

enum Clock {
    static let time: Date.FormatStyle = .dateTime.hour().minute()

    static func time(_ date: Date) -> String {
        date.formatted(time)
    }

    static func dayTitle(_ date: Date, relativeTo reference: Date = .now) -> String {
        if Calendar.current.isDate(date, inSameDayAs: reference) {
            return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        }
        return date.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }
}

extension Activity {
    var color: Color { Color(hex: colorHex) }
}

// MARK: - Local settings

/// `UserDefaults`-backed preference keys (via `@AppStorage`).
enum AppSettings {
    /// Today timeline: scale each interval's vertical space by its duration.
    static let scaleTimelineByDuration = "timeline.scaleByDuration"
    static let scaleTimelineByDurationDefault = true
}
