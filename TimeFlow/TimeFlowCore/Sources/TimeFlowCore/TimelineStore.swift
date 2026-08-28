import Foundation
import SwiftData

/// Describes the most recent capture so it can be undone.
public struct CaptureUndo: Sendable {
    public enum Kind: Sendable {
        /// The capture created the very first period.
        case firstStart
        /// The capture closed a period and opened a new one.
        case transition
    }

    public let kind: Kind
    public let newPeriodID: PersistentIdentifier
    public let previousPeriodID: PersistentIdentifier?
    public let at: Date
}

/// Owns every mutation of the timeline so the continuity invariants hold:
///
/// 1. While tracking, periods are gap-free and non-overlapping
///    (`a.endTime == b.startTime` for adjacent `a`, `b`).
/// 2. Exactly one period is open (`endTime == nil`) while tracking.
/// 3. Moving a shared boundary updates both adjacent periods.
/// 4. Deleting a boundary merges the neighbours with no gap.
/// 5. Adding a boundary splits a period with no gap or overlap.
/// 6. Midnight is never stored as a transition.
///
/// Views read the published `periods` / `activities` snapshots and call the
/// mutating methods; the store re-fetches and republishes after each change.
@MainActor
@Observable
public final class TimelineStore {
    public private(set) var periods: [Period] = []
    public private(set) var activities: [Activity] = []
    public private(set) var lastCapture: CaptureUndo?

    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
        reload()
    }

    // MARK: - Derived state

    /// The single open period, if tracking.
    public var openPeriod: Period? { periods.first { $0.isOpen } }
    public var isTracking: Bool { openPeriod != nil }

    // MARK: - Loading

    public func reload() {
        let periodDescriptor = FetchDescriptor<Period>(
            sortBy: [SortDescriptor(\.startTime, order: .forward)]
        )
        periods = (try? context.fetch(periodDescriptor)) ?? []

        // Built-ins are seeded with sortOrder 0..<n and customs continue from n,
        // so sortOrder alone gives "built-ins first, then customs by creation".
        let activityDescriptor = FetchDescriptor<Activity>(
            predicate: #Predicate { !$0.isArchived },
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        activities = (try? context.fetch(activityDescriptor)) ?? []
    }

    // MARK: - Seeding

    /// Insert the starter activities exactly once, when no activities exist.
    public func seedDefaultActivitiesIfNeeded() {
        let existing = (try? context.fetchCount(FetchDescriptor<Activity>())) ?? 0
        guard existing == 0 else { return }
        for (index, spec) in DefaultActivities.all.enumerated() {
            context.insert(
                Activity(
                    name: spec.name,
                    iconSystemName: spec.icon,
                    colorHex: spec.colorHex,
                    isBuiltIn: true,
                    sortOrder: index
                )
            )
        }
        try? context.save()
        reload()
    }

    // MARK: - Capture

    /// Begin tracking by creating the first open period.
    @discardableResult
    public func startTracking(at date: Date = .now) throws -> Period {
        guard openPeriod == nil else { throw TimelineError.invalidTrackingState }
        let period = Period(startTime: date)
        context.insert(period)
        try context.save()
        reload()
        lastCapture = CaptureUndo(
            kind: .firstStart,
            newPeriodID: period.persistentModelID,
            previousPeriodID: nil,
            at: date
        )
        return period
    }

    /// Record "my activity changed now" at `touchDown`.
    ///
    /// Uses the caller-supplied timestamp (the touch-down instant), not the
    /// moment this method runs, so the animated hold does not skew the boundary.
    @discardableResult
    public func capture(at touchDown: Date = .now) throws -> Period {
        guard let open = openPeriod else {
            return try startTracking(at: touchDown)
        }
        guard touchDown > open.startTime else { throw TimelineError.timestampOutOfOrder }

        let now = Date.now
        open.endTime = touchDown
        open.updatedAt = now

        let next = Period(startTime: touchDown)
        context.insert(next)
        try context.save()
        reload()

        lastCapture = CaptureUndo(
            kind: .transition,
            newPeriodID: next.persistentModelID,
            previousPeriodID: open.persistentModelID,
            at: touchDown
        )
        return next
    }

    /// Remove the most recent capture and restore the previous open period.
    public func undoLastCapture() throws {
        guard let undo = lastCapture else { return }
        defer { lastCapture = nil }

        guard let newPeriod = period(with: undo.newPeriodID) else { return }
        guard newPeriod.isOpen else { throw TimelineError.invalidTrackingState }

        switch undo.kind {
        case .firstStart:
            context.delete(newPeriod)
        case .transition:
            if let previousID = undo.previousPeriodID,
               let previous = period(with: previousID) {
                previous.endTime = nil
                previous.updatedAt = .now
            }
            context.delete(newPeriod)
        }
        try context.save()
        reload()
    }

    public func clearUndo() {
        lastCapture = nil
    }

    // MARK: - Labelling

    public func setActivity(_ activity: Activity?, for period: Period) throws {
        period.activity = activity
        period.updatedAt = .now
        try context.save()
        reload()
    }

    @discardableResult
    public func createActivity(
        name: String,
        iconSystemName: String,
        colorHex: String
    ) throws -> Activity {
        let nextOrder = (activities.map(\.sortOrder).max() ?? -1) + 1
        let activity = Activity(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconSystemName: iconSystemName,
            colorHex: colorHex,
            isBuiltIn: false,
            sortOrder: nextOrder
        )
        context.insert(activity)
        try context.save()
        reload()
        return activity
    }

    /// Activities used most recently, for the top of the picker.
    public func recentActivities(limit: Int = 4) -> [Activity] {
        var seen = Set<PersistentIdentifier>()
        var result: [Activity] = []
        for period in periods.sorted(by: { $0.updatedAt > $1.updatedAt }) {
            guard let activity = period.activity, !activity.isArchived else { continue }
            if seen.insert(activity.persistentModelID).inserted {
                result.append(activity)
                if result.count == limit { break }
            }
        }
        return result
    }

    // MARK: - Editing boundaries

    /// Move the shared boundary that starts the period after `earlier`.
    ///
    /// The new time must lie strictly between `earlier.startTime` and the end of
    /// the later period (or `reference` if the later period is still open).
    public func moveBoundary(
        after earlier: Period,
        to newTime: Date,
        reference: Date = .now
    ) throws {
        guard let later = periodImmediatelyAfter(earlier) else {
            throw TimelineError.periodsNotAdjacent
        }
        let upperBound = later.endTime ?? reference
        guard newTime > earlier.startTime, newTime < upperBound else {
            throw TimelineError.timestampOutOfOrder
        }
        let now = Date.now
        earlier.endTime = newTime
        earlier.updatedAt = now
        later.startTime = newTime
        later.updatedAt = now
        try context.save()
        invalidateUndo()
        reload()
    }

    /// Split `period` at `time`, inserting a transition. Both halves keep the
    /// original activity; they can then be relabelled independently.
    public func insertBoundary(
        in period: Period,
        at time: Date,
        reference: Date = .now
    ) throws {
        let upperBound = period.endTime ?? reference
        guard time > period.startTime, time < upperBound else {
            throw TimelineError.timestampOutOfOrder
        }
        let laterHalf = Period(
            startTime: time,
            endTime: period.endTime,
            activity: period.activity
        )
        period.endTime = time
        period.updatedAt = .now
        context.insert(laterHalf)
        try context.save()
        invalidateUndo()
        reload()
    }

    /// Delete the shared boundary after `earlier`, merging it with the next
    /// period. If the two carry different activities, `resolution` is required.
    public func deleteBoundary(
        after earlier: Period,
        resolution: MergeResolution? = nil
    ) throws {
        guard let later = periodImmediatelyAfter(earlier) else {
            throw TimelineError.periodsNotAdjacent
        }

        let sameActivity = earlier.activity?.persistentModelID == later.activity?.persistentModelID
        if !sameActivity {
            guard let resolution else { throw TimelineError.mergeNeedsResolution }
            switch resolution {
            case .keepEarlier: break
            case .keepLater: earlier.activity = later.activity
            case .unclassified: earlier.activity = nil
            }
        }

        earlier.endTime = later.endTime
        earlier.updatedAt = .now
        context.delete(later)
        try context.save()
        invalidateUndo()
        reload()
    }

    /// Whether deleting the boundary after `earlier` needs a manual resolution.
    public func boundaryDeleteNeedsResolution(after earlier: Period) -> Bool {
        guard let later = periodImmediatelyAfter(earlier) else { return false }
        return earlier.activity?.persistentModelID != later.activity?.persistentModelID
    }

    // MARK: - Helpers

    public func period(with id: PersistentIdentifier) -> Period? {
        periods.first { $0.persistentModelID == id }
    }

    /// The period whose start matches `earlier.endTime`. Relies on invariant 1.
    public func periodImmediatelyAfter(_ earlier: Period) -> Period? {
        guard let index = periods.firstIndex(where: { $0.persistentModelID == earlier.persistentModelID }),
              periods.indices.contains(index + 1) else {
            return nil
        }
        return periods[index + 1]
    }

    /// The period whose end matches `later.startTime`. Relies on invariant 1.
    public func periodImmediatelyBefore(_ later: Period) -> Period? {
        guard let index = periods.firstIndex(where: { $0.persistentModelID == later.persistentModelID }),
              index > 0 else {
            return nil
        }
        return periods[index - 1]
    }

    private func invalidateUndo() {
        lastCapture = nil
    }
}
