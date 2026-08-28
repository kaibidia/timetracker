import Foundation
import SwiftData

/// A period as it should be *displayed* on one calendar day.
///
/// A period that crosses midnight stays a single stored `Period`; for a daily
/// view it is clamped to the day's bounds and flagged as continuing. This is a
/// pure view-model transform and never mutates stored data.
public struct DaySegment: Identifiable, Sendable {
    public let id: UUID
    public let period: PersistentIdentifier
    public let activityName: String?
    public let displayStart: Date
    public let displayEnd: Date
    /// The stored period started before `displayStart` (previous day).
    public let continuesFromPreviousDay: Bool
    /// The stored period ends after `displayEnd`, or is still open.
    public let continuesIntoNextDay: Bool
    /// The stored period has no `endTime`.
    public let isOpen: Bool

    public var displayDuration: TimeInterval {
        max(0, displayEnd.timeIntervalSince(displayStart))
    }

    public init(
        id: UUID = UUID(),
        period: PersistentIdentifier,
        activityName: String?,
        displayStart: Date,
        displayEnd: Date,
        continuesFromPreviousDay: Bool,
        continuesIntoNextDay: Bool,
        isOpen: Bool
    ) {
        self.id = id
        self.period = period
        self.activityName = activityName
        self.displayStart = displayStart
        self.displayEnd = displayEnd
        self.continuesFromPreviousDay = continuesFromPreviousDay
        self.continuesIntoNextDay = continuesIntoNextDay
        self.isOpen = isOpen
    }
}

public enum DayTimeline {
    /// Clamp every period overlapping `day` to that day's bounds, newest first.
    ///
    /// - Parameters:
    ///   - periods: all stored periods (any order).
    ///   - day: any instant within the target calendar day.
    ///   - reference: "now", used to bound the open period.
    ///   - calendar: calendar used to find the day's start / end.
    public static func segments(
        for periods: [Period],
        on day: Date,
        reference: Date = .now,
        calendar: Calendar = .current
    ) -> [DaySegment] {
        let dayStart = calendar.startOfDay(for: day)
        guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return [] }

        var result: [DaySegment] = []
        for period in periods {
            let rawEnd = period.endTime ?? reference
            let effectiveEnd = max(period.startTime, rawEnd)
            // Overlap test against [dayStart, dayEnd).
            guard period.startTime < dayEnd, effectiveEnd > dayStart else { continue }

            let clampedStart = max(period.startTime, dayStart)
            let clampedEnd = min(effectiveEnd, dayEnd)

            result.append(
                DaySegment(
                    period: period.persistentModelID,
                    activityName: period.activity?.name,
                    displayStart: clampedStart,
                    displayEnd: clampedEnd,
                    continuesFromPreviousDay: period.startTime < dayStart,
                    continuesIntoNextDay: period.isOpen || effectiveEnd > dayEnd,
                    isOpen: period.isOpen
                )
            )
        }
        return result.sorted { $0.displayStart > $1.displayStart }
    }
}
