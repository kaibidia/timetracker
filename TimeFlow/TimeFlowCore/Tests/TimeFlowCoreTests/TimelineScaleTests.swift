import Foundation
import Testing
@testable import TimeFlowCore

@Suite("Duration → timeline height")
struct TimelineScaleTests {

    private func h(_ minutes: Double) -> Double {
        TimelineScale.segmentHeight(forDuration: minutes * 60)
    }

    @Test("Longer intervals are taller, across the meaningful range")
    func monotonic() {
        let ladder = [h(10), h(30), h(60), h(120), h(240)]
        for (a, b) in zip(ladder, ladder.dropFirst()) {
            #expect(b > a)
        }
    }

    @Test("Short intervals keep a readable floor")
    func floor() {
        #expect(h(0) == TimelineScale.minHeight)
        #expect(h(1) >= TimelineScale.minHeight)
        #expect(h(2) < TimelineScale.compactHeightThreshold) // 2 min → compact layout
    }

    @Test("Very long intervals are compressed and capped")
    func capped() {
        #expect(h(60 * 24) < TimelineScale.maxHeight)
        #expect(h(60 * 24) > h(240))          // still grows past 4h…
        #expect(h(60 * 24) - h(240) < h(240) - h(60)) // …but far less than earlier growth
    }

    @Test("Growth diminishes as duration rises")
    func diminishingReturns() {
        let firstHour = h(60) - h(0)
        let secondHour = h(120) - h(60)
        let fourthHour = h(240) - h(180)
        #expect(firstHour > secondHour)
        #expect(secondHour > fourthHour)
    }
}
