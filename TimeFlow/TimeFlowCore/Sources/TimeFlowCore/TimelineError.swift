import Foundation

/// Errors raised when an edit would violate a timeline invariant.
public enum TimelineError: Error, Equatable, Sendable {
    /// A new timestamp is not strictly between its neighbouring transitions.
    case timestampOutOfOrder
    /// The referenced periods are not adjacent, so there is no shared boundary.
    case periodsNotAdjacent
    /// The operation requires an open period and there is none (or vice versa).
    case invalidTrackingState
    /// A boundary delete between differently-labelled periods needs a resolution.
    case mergeNeedsResolution
}

/// How to label the merged period when deleting a boundary between two periods
/// that carry different activities.
public enum MergeResolution: Sendable {
    case keepEarlier
    case keepLater
    case unclassified
}
