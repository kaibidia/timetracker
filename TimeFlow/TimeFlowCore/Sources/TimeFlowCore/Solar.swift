import Foundation

/// Local sunrise / sunset, computed from the standard sunrise equation.
///
/// Accurate to roughly a minute for temperate latitudes — more than enough to
/// switch the app between its light and dark palettes at dusk and dawn. No
/// network or system service is used; only the coordinate and the date.
public enum Solar {
    private static let degrees = Double.pi / 180

    /// Sunrise and sunset instants for the solar day containing `date`.
    ///
    /// Returns `nil` inside the polar circles on days when the sun stays either
    /// above or below the horizon the whole day.
    public static func sunTimes(
        latitude: Double,
        longitude: Double,
        date: Date = .now
    ) -> (sunrise: Date, sunset: Date)? {
        let julianDate = date.timeIntervalSince1970 / 86_400 + 2_440_587.5
        let n = (julianDate - 2_451_545.0 + 0.0008).rounded()

        let meanSolarNoon = n - longitude / 360
        let meanAnomaly = (357.5291 + 0.98560028 * meanSolarNoon)
            .truncatingRemainder(dividingBy: 360)
        let m = meanAnomaly * degrees
        let center = 1.9148 * sin(m) + 0.0200 * sin(2 * m) + 0.0003 * sin(3 * m)
        let eclipticLongitude = (meanAnomaly + center + 180 + 102.9372)
            .truncatingRemainder(dividingBy: 360)
        let lambda = eclipticLongitude * degrees

        let solarTransit = 2_451_545.0 + meanSolarNoon
            + 0.0053 * sin(m) - 0.0069 * sin(2 * lambda)

        let sinDeclination = sin(lambda) * sin(23.4397 * degrees)
        let cosDeclination = cos(asin(sinDeclination))
        let phi = latitude * degrees
        let cosHourAngle = (sin(-0.833 * degrees) - sin(phi) * sinDeclination)
            / (cos(phi) * cosDeclination)
        guard (-1...1).contains(cosHourAngle) else { return nil }

        let hourAngle = acos(cosHourAngle) / degrees
        return (
            sunrise: instant(fromJulian: solarTransit - hourAngle / 360),
            sunset: instant(fromJulian: solarTransit + hourAngle / 360)
        )
    }

    /// Whether the sun is above the horizon at `date` for the given coordinate.
    /// `nil` during polar day / night (caller should fall back).
    public static func isDaytime(
        latitude: Double,
        longitude: Double,
        at date: Date = .now
    ) -> Bool? {
        guard let times = sunTimes(latitude: latitude, longitude: longitude, date: date) else {
            return nil
        }
        return date >= times.sunrise && date < times.sunset
    }

    private static func instant(fromJulian julianDate: Double) -> Date {
        Date(timeIntervalSince1970: (julianDate - 2_440_587.5) * 86_400)
    }
}
