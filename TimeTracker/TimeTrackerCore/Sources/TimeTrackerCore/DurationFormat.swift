import Foundation

public enum DurationFormat {
    /// `"1h 24m"`, `"37m"`, `"2h"`. Truncates to whole minutes; never negative.
    public static func short(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        switch (hours, minutes) {
        case (0, _): return "\(minutes)m"
        case (_, 0): return "\(hours)h"
        default: return "\(hours)h \(minutes)m"
        }
    }
}
