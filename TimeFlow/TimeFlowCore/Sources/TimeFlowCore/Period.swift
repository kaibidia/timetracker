import Foundation
import SwiftData

/// A continuous span of time between two transitions.
///
/// The timeline is stored as a list of periods rather than as raw transition
/// points. A shared boundary is represented implicitly: `a.endTime == b.startTime`
/// for adjacent periods `a` and `b`. The `TimelineStore` is the only thing that
/// mutates periods, so it can keep that continuity invariant true.
///
/// `endTime == nil` marks the single open/current period.
@Model
public final class Period {
    public private(set) var id: UUID
    public var startTime: Date
    public var endTime: Date?
    public var activity: Activity?
    public private(set) var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date? = nil,
        activity: Activity? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.activity = activity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var isOpen: Bool { endTime == nil }

    /// Duration up to `endTime`, or up to `reference` for the open period.
    public func duration(asOf reference: Date = .now) -> TimeInterval {
        max(0, (endTime ?? reference).timeIntervalSince(startTime))
    }
}
