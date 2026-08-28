import SwiftUI
import CoreLocation
import TimeFlowCore

/// Chooses the app's palette from local sunrise / sunset — the same idea as
/// iOS's "Sunset to Sunrise" automatic appearance.
///
/// Uses a one-shot, coarse Core Location fix. If permission is denied or a fix
/// isn't available, it falls back to a fixed clock window (`DayNight`), so the
/// app still themes sensibly with no location at all.
@MainActor
@Observable
final class AppearanceModel: NSObject, CLLocationManagerDelegate {
    private(set) var colorScheme: ColorScheme

    private let manager = CLLocationManager()
    private var coordinate: CLLocationCoordinate2D?

    override init() {
        colorScheme = Self.resolve(coordinate: nil)
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        requestLocationIfPossible()
    }

    /// Recompute from the current time (call each minute and on foreground).
    func refresh() {
        apply(Self.resolve(coordinate: coordinate))
    }

    // MARK: - Resolution

    private static func resolve(coordinate: CLLocationCoordinate2D?) -> ColorScheme {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ForceNight") { return .dark }
        if args.contains("-ForceDay") { return .light }
        #endif
        if let coordinate,
           let daytime = Solar.isDaytime(latitude: coordinate.latitude, longitude: coordinate.longitude) {
            return daytime ? .light : .dark
        }
        return DayNight.colorScheme()
    }

    private func apply(_ scheme: ColorScheme) {
        guard scheme != colorScheme else { return }
        withAnimation(.easeInOut(duration: 0.6)) { colorScheme = scheme }
    }

    // MARK: - Location

    private func requestLocationIfPossible() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ForceDay") || args.contains("-ForceNight") { return }
        #endif
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break // denied / restricted → clock fallback
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            requestLocationIfPossible()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        MainActor.assumeIsolated {
            coordinate = location.coordinate
            refresh()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep whatever we have; the clock fallback covers us.
    }
}
