import Foundation

/// Maps an interval's duration to the vertical distance between its two
/// timestamp nodes on the Today timeline. Presentation only — nothing here is
/// stored, and it is derived purely from a duration.
///
/// ## Formula
///
///     minutes  = max(0, seconds / 60)
///     fraction = minutes / (minutes + halfSaturationMinutes)   // 0 ..< 1
///     height   = minHeight + (maxHeight - minHeight) * fraction
///
/// This is a hyperbolic saturation curve:
///
/// - **monotonic** — more duration always means more height;
/// - **diminishing** — each extra minute adds less height than the last, so a
///   4-hour block is not four times a 1-hour block;
/// - **bounded** — height approaches, but never reaches, `maxHeight`, so an
///   8-hour sleep block is tall but not absurd;
/// - **readable floor** — the shortest interval still gets `minHeight`, enough
///   to stay legible and tappable.
///
/// `halfSaturationMinutes` (75) is the duration at which the segment reaches the
/// midpoint of its height range.
public enum TimelineScale {
    public static let minHeight: Double = 44
    public static let maxHeight: Double = 300
    public static let halfSaturationMinutes: Double = 75

    /// Below this height a row should use its compact single-line presentation.
    /// Corresponds to roughly a 20-minute interval.
    public static let compactHeightThreshold: Double = 96

    public static func segmentHeight(forDuration seconds: TimeInterval) -> Double {
        let minutes = max(0, seconds / 60)
        let fraction = minutes / (minutes + halfSaturationMinutes)
        return minHeight + (maxHeight - minHeight) * fraction
    }
}
