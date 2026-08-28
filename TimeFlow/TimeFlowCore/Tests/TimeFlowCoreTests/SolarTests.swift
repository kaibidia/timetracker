import Foundation
import Testing
@testable import TimeFlowCore

@Suite("Sunrise / sunset")
struct SolarTests {

    private func utc(_ y: Int, _ m: Int, _ d: Int, _ hh: Int = 12, _ mm: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.date(from: DateComponents(year: y, month: m, day: d, hour: hh, minute: mm))!
    }

    /// NOAA reference: New York, 2025-06-21 — sunrise 09:25 UTC, sunset 00:31 UTC (next day).
    @Test("New York around the June solstice")
    func newYorkSolstice() throws {
        let times = try #require(Solar.sunTimes(latitude: 40.7128, longitude: -74.0060, date: utc(2025, 6, 21)))
        #expect(abs(times.sunrise.timeIntervalSince(utc(2025, 6, 21, 9, 25))) < 360)
        #expect(abs(times.sunset.timeIntervalSince(utc(2025, 6, 22, 0, 31))) < 360)
    }

    /// NOAA reference: London, 2025-12-21 — sunrise 08:04 UTC, sunset 15:53 UTC.
    @Test("London around the December solstice")
    func londonSolstice() throws {
        let times = try #require(Solar.sunTimes(latitude: 51.5072, longitude: -0.1276, date: utc(2025, 12, 21)))
        #expect(abs(times.sunrise.timeIntervalSince(utc(2025, 12, 21, 8, 4))) < 360)
        #expect(abs(times.sunset.timeIntervalSince(utc(2025, 12, 21, 15, 53))) < 360)
    }

    @Test("Day length is ~12h at the equinox")
    func equinoxDayLength() throws {
        let times = try #require(Solar.sunTimes(latitude: 51.4769, longitude: 0, date: utc(2025, 3, 20)))
        let dayLength = times.sunset.timeIntervalSince(times.sunrise)
        #expect(abs(dayLength - 12 * 3600) < 20 * 60)
    }

    @Test("isDaytime tracks the computed window")
    func daytimeWindow() {
        // NYC, mid-afternoon local (19:00 UTC) in summer → daytime.
        #expect(Solar.isDaytime(latitude: 40.7128, longitude: -74.0060, at: utc(2025, 6, 21, 19, 0)) == true)
        // NYC, small hours local (05:00 UTC) → night.
        #expect(Solar.isDaytime(latitude: 40.7128, longitude: -74.0060, at: utc(2025, 6, 21, 5, 0)) == false)
    }

    @Test("Polar day returns nil")
    func polarDay() {
        #expect(Solar.sunTimes(latitude: 78.22, longitude: 15.65, date: utc(2025, 6, 21)) == nil)
        #expect(Solar.isDaytime(latitude: 78.22, longitude: 15.65, at: utc(2025, 6, 21)) == nil)
    }
}
