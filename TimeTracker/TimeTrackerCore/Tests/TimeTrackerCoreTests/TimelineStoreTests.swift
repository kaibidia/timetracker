import Foundation
import SwiftData
import Testing
@testable import TimeTrackerCore

@MainActor
@Suite("Timeline invariants and editing")
struct TimelineStoreTests {

    // MARK: - Fixtures

    private func makeStore() throws -> TimelineStore {
        let container = try TimeTrackerSchema.makeInMemoryContainer()
        return TimelineStore(context: ModelContext(container))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func date(_ y: Int, _ m: Int, _ d: Int, _ hh: Int, _ mm: Int) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hh, minute: mm))!
    }

    /// Adjacent stored periods must share their boundary exactly.
    private func assertContinuous(_ store: TimelineStore, sourceLocation: SourceLocation = #_sourceLocation) {
        let sorted = store.periods.sorted { $0.startTime < $1.startTime }
        for (a, b) in zip(sorted, sorted.dropFirst()) {
            #expect(a.endTime == b.startTime, "gap or overlap between periods", sourceLocation: sourceLocation)
        }
        #expect(sorted.filter(\.isOpen).count <= 1, "more than one open period", sourceLocation: sourceLocation)
    }

    // MARK: - Capture

    @Test("First manual start creates exactly one open period")
    func firstStart() throws {
        let store = try makeStore()
        let t0 = date(2026, 8, 28, 9, 0)
        try store.capture(at: t0)

        #expect(store.periods.count == 1)
        #expect(store.openPeriod?.startTime == t0)
        #expect(store.isTracking)
    }

    @Test("Capture uses the touch-down timestamp, not the commit time")
    func touchDownTimestamp() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        let touchDown = date(2026, 8, 28, 10, 30)

        try store.capture(at: touchDown)

        let closed = store.periods.first { !$0.isOpen }
        #expect(closed?.endTime == touchDown)
        #expect(store.openPeriod?.startTime == touchDown)
    }

    @Test("A transition closes the previous period and opens a new one, gap-free")
    func transitionContinuity() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 9, 45))
        try store.capture(at: date(2026, 8, 28, 11, 0))

        #expect(store.periods.count == 3)
        #expect(store.periods.filter(\.isOpen).count == 1)
        assertContinuous(store)
    }

    @Test("Capture rejects a timestamp at or before the open period start")
    func rejectsOutOfOrderCapture() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        #expect(throws: TimelineError.timestampOutOfOrder) {
            try store.capture(at: date(2026, 8, 28, 8, 30))
        }
        #expect(store.periods.count == 1)
    }

    // MARK: - Undo

    @Test("Undo of a transition restores the previous open period")
    func undoTransition() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        #expect(store.periods.count == 2)

        try store.undoLastCapture()

        #expect(store.periods.count == 1)
        #expect(store.openPeriod?.startTime == date(2026, 8, 28, 9, 0))
        #expect(store.lastCapture == nil)
    }

    @Test("Undo of the first start clears the timeline")
    func undoFirstStart() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))

        try store.undoLastCapture()

        #expect(store.periods.isEmpty)
        #expect(!store.isTracking)
    }

    @Test("A structural edit invalidates the pending undo")
    func structuralEditInvalidatesUndo() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        let earlier = store.periods.sorted { $0.startTime < $1.startTime }[0]

        try store.insertBoundary(in: earlier, at: date(2026, 8, 28, 9, 30))

        #expect(store.lastCapture == nil)
    }

    // MARK: - Labelling

    @Test("Completed and current periods can be labelled and relabelled")
    func labelling() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()
        let work = store.activities.first { $0.name == "Work" }!
        let food = store.activities.first { $0.name == "Food" }!

        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        let completed = store.periods.sorted { $0.startTime < $1.startTime }[0]
        let current = store.openPeriod!

        try store.setActivity(work, for: completed)
        try store.setActivity(food, for: current)
        #expect(completed.activity?.name == "Work")
        #expect(current.activity?.name == "Food")

        try store.setActivity(work, for: current)
        #expect(current.activity?.name == "Work")
    }

    @Test("A custom activity is created and appears in the active list")
    func createCustomActivity() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()

        let greek = try store.createActivity(name: "Greek", iconSystemName: "textformat", colorHex: "#B5643C")

        #expect(store.activities.contains { $0.persistentModelID == greek.persistentModelID })
        #expect(!greek.isBuiltIn)
    }

    // MARK: - Move boundary

    @Test("Moving a shared boundary updates both adjacent periods")
    func moveBoundary() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        try store.capture(at: date(2026, 8, 28, 11, 0))
        let sorted = store.periods.sorted { $0.startTime < $1.startTime }
        let first = sorted[0]

        try store.moveBoundary(after: first, to: date(2026, 8, 28, 10, 15))

        let after = store.periods.sorted { $0.startTime < $1.startTime }
        #expect(after[0].endTime == date(2026, 8, 28, 10, 15))
        #expect(after[1].startTime == date(2026, 8, 28, 10, 15))
        assertContinuous(store)
    }

    @Test("A boundary cannot move past its neighbouring transitions")
    func moveBoundaryRejectsInvalidOrdering() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        try store.capture(at: date(2026, 8, 28, 11, 0))
        let first = store.periods.sorted { $0.startTime < $1.startTime }[0]

        #expect(throws: TimelineError.timestampOutOfOrder) {
            try store.moveBoundary(after: first, to: date(2026, 8, 28, 8, 30))
        }
        #expect(throws: TimelineError.timestampOutOfOrder) {
            try store.moveBoundary(after: first, to: date(2026, 8, 28, 11, 30))
        }
    }

    // MARK: - Insert boundary

    @Test("Inserting a boundary splits a period with no gap and inherits the activity")
    func insertBoundary() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()
        let work = store.activities.first { $0.name == "Work" }!

        try store.capture(at: date(2026, 8, 28, 18, 0))
        try store.capture(at: date(2026, 8, 28, 21, 0))
        let target = store.periods.sorted { $0.startTime < $1.startTime }[0]
        try store.setActivity(work, for: target)

        try store.insertBoundary(in: target, at: date(2026, 8, 28, 19, 20))

        let sorted = store.periods.sorted { $0.startTime < $1.startTime }
        #expect(sorted.count == 3)
        #expect(sorted[0].endTime == date(2026, 8, 28, 19, 20))
        #expect(sorted[1].startTime == date(2026, 8, 28, 19, 20))
        #expect(sorted[1].endTime == date(2026, 8, 28, 21, 0))
        #expect(sorted[0].activity?.name == "Work")
        #expect(sorted[1].activity?.name == "Work")
        assertContinuous(store)
    }

    @Test("Inserting a boundary outside a period is rejected")
    func insertBoundaryOutOfRange() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 18, 0))
        try store.capture(at: date(2026, 8, 28, 21, 0))
        let target = store.periods.sorted { $0.startTime < $1.startTime }[0]

        #expect(throws: TimelineError.timestampOutOfOrder) {
            try store.insertBoundary(in: target, at: date(2026, 8, 28, 22, 0))
        }
    }

    // MARK: - Delete boundary

    @Test("Deleting a boundary between same-activity periods merges them silently")
    func deleteBoundarySameActivity() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()
        let work = store.activities.first { $0.name == "Work" }!

        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        try store.capture(at: date(2026, 8, 28, 11, 0))
        let sorted = store.periods.sorted { $0.startTime < $1.startTime }
        try store.setActivity(work, for: sorted[0])
        try store.setActivity(work, for: sorted[1])

        try store.deleteBoundary(after: sorted[0])

        let after = store.periods.sorted { $0.startTime < $1.startTime }
        #expect(after.count == 2)
        #expect(after[0].startTime == date(2026, 8, 28, 9, 0))
        #expect(after[0].endTime == date(2026, 8, 28, 11, 0))
        #expect(after[0].activity?.name == "Work")
        assertContinuous(store)
    }

    @Test("Deleting a boundary between different activities requires a resolution")
    func deleteBoundaryNeedsResolution() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()
        let work = store.activities.first { $0.name == "Work" }!
        let food = store.activities.first { $0.name == "Food" }!

        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        try store.capture(at: date(2026, 8, 28, 11, 0))
        let sorted = store.periods.sorted { $0.startTime < $1.startTime }
        try store.setActivity(work, for: sorted[0])
        try store.setActivity(food, for: sorted[1])

        #expect(store.boundaryDeleteNeedsResolution(after: sorted[0]))
        #expect(throws: TimelineError.mergeNeedsResolution) {
            try store.deleteBoundary(after: sorted[0])
        }

        try store.deleteBoundary(after: sorted[0], resolution: .keepLater)
        let after = store.periods.sorted { $0.startTime < $1.startTime }
        #expect(after.count == 2)
        #expect(after[0].activity?.name == "Food")
    }

    @Test("Deleting the boundary before the open period keeps tracking open")
    func deleteBoundaryIntoOpenPeriod() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        let earlier = store.periods.sorted { $0.startTime < $1.startTime }[0]

        try store.deleteBoundary(after: earlier)

        #expect(store.periods.count == 1)
        #expect(store.openPeriod?.startTime == date(2026, 8, 28, 9, 0))
    }

    // MARK: - Midnight

    @Test("A period crossing midnight stays one stored period but splits visually")
    func midnightCrossing() throws {
        let store = try makeStore()
        try store.capture(at: date(2026, 8, 28, 23, 0))
        try store.capture(at: date(2026, 8, 28, 23, 30))
        try store.capture(at: date(2026, 8, 29, 0, 45))

        // The 23:30 -> 00:45 span is a single stored period, no 00:00 transition.
        let crossing = store.periods.first { $0.startTime == date(2026, 8, 28, 23, 30) }!
        #expect(crossing.endTime == date(2026, 8, 29, 0, 45))
        #expect(!store.periods.contains { $0.startTime == date(2026, 8, 29, 0, 0) })

        let friday = DayTimeline.segments(
            for: store.periods, on: date(2026, 8, 28, 12, 0),
            reference: date(2026, 8, 29, 1, 0), calendar: calendar
        )
        let fridayCrossing = friday.first { $0.period == crossing.persistentModelID }!
        #expect(fridayCrossing.displayStart == date(2026, 8, 28, 23, 30))
        #expect(fridayCrossing.displayEnd == date(2026, 8, 29, 0, 0))
        #expect(fridayCrossing.continuesIntoNextDay)

        let saturday = DayTimeline.segments(
            for: store.periods, on: date(2026, 8, 29, 12, 0),
            reference: date(2026, 8, 29, 1, 0), calendar: calendar
        )
        let saturdayCrossing = saturday.first { $0.period == crossing.persistentModelID }!
        #expect(saturdayCrossing.displayStart == date(2026, 8, 29, 0, 0))
        #expect(saturdayCrossing.displayEnd == date(2026, 8, 29, 0, 45))
        #expect(saturdayCrossing.continuesFromPreviousDay)

        // Visual split did not mutate stored data.
        #expect(crossing.startTime == date(2026, 8, 28, 23, 30))
        #expect(crossing.endTime == date(2026, 8, 29, 0, 45))
    }

    // MARK: - Seeding & recents

    @Test("Default activities seed once and only once")
    func seedIdempotent() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()
        let firstCount = store.activities.count
        store.seedDefaultActivitiesIfNeeded()

        #expect(firstCount == DefaultActivities.all.count)
        #expect(store.activities.count == firstCount)
    }

    @Test("Recent activities are ordered by most recent use")
    func recentActivities() throws {
        let store = try makeStore()
        store.seedDefaultActivitiesIfNeeded()
        let work = store.activities.first { $0.name == "Work" }!
        let food = store.activities.first { $0.name == "Food" }!

        try store.capture(at: date(2026, 8, 28, 9, 0))
        try store.capture(at: date(2026, 8, 28, 10, 0))
        let sorted = store.periods.sorted { $0.startTime < $1.startTime }
        try store.setActivity(work, for: sorted[0])
        try store.setActivity(food, for: sorted[1])

        let recents = store.recentActivities(limit: 4)
        #expect(recents.first?.name == "Food")
        #expect(recents.contains { $0.name == "Work" })
    }
}
