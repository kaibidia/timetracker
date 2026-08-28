import SwiftUI

/// TimeFlow palette — warm ember over deep plum. Every token is defined for
/// both light and dark.
///
/// Source colours:
/// - Deep plum   `#2B1E2E` — dark background anchor
/// - Mulberry    `#4B2E3F` — secondary dark surface
/// - Burgundy    `#6D3A4E` — muted accent
/// - Terracotta  `#9B4D3A` — activity/accent option
/// - Ember orange `#E67C3C` — primary interactive accent
/// - Warm apricot `#FFB26B` — highlights / ripple / fill
/// - Cream       `#F8E9D6` — warm light background
enum AutumnTheme {
    static let background     = Color(light: 0xF8E9D6, dark: 0x2B1E2E)
    static let surface        = Color(light: 0xFDF4E7, dark: 0x3C2536)
    static let surfaceRaised   = Color(light: 0xFFFFFF, dark: 0x4B2E3F)
    static let primaryText     = Color(light: 0x2B1E2E, dark: 0xF8E9D6)
    static let secondaryText   = Color(light: 0x8A6B72, dark: 0xC9A9B0)
    static let accent          = Color(light: 0xD9662C, dark: 0xE67C3C)
    static let accentSoft      = Color(light: 0xFFB26B, dark: 0x6D3A4E)
    static let hairline        = Color(light: 0xEAD8C6, dark: 0x4B2E3F)
    static let captureCore     = Color(light: 0xE67C3C, dark: 0xE67C3C)
    static let captureFill     = Color(light: 0xFFB26B, dark: 0xFFB26B)
    static let captureRim      = Color(light: 0xF3DBC1, dark: 0x4B2E3F)
    static let ripple          = Color(light: 0xE67C3C, dark: 0xFFB26B)

    /// Coherent warm set for custom activities — terracotta / ember / burgundy
    /// family, kept mutually distinguishable.
    static let activityPalette: [String] = [
        "#9B4D3A", "#E67C3C", "#C25E3A", "#6D3A4E",
        "#A34A5E", "#D98A4E", "#B5643C", "#8C5A3C",
        "#7A4A5C", "#C77D5A", "#E0A15C", "#5E4A6B"
    ]
}

/// The palette follows the clock, not the system appearance: the light
/// (cream) palette during the day, the dark (deep plum) palette at night.
enum DayNight {
    /// Daytime is 07:00–18:59 local; everything else is night.
    static func colorScheme(at date: Date = .now, calendar: Calendar = .current) -> ColorScheme {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-ForceNight") { return .dark }
        if args.contains("-ForceDay") { return .light }
        #endif
        return (7..<19).contains(calendar.component(.hour, from: date)) ? .light : .dark
    }
}

extension Color {
    init(light: UInt, dark: UInt) {
        self.init(uiColor: UIColor { traits in
            UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }

    /// Parses `#RRGGBB` (or `RRGGBB`); falls back to a mid grey.
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "# "))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        guard cleaned.count == 6 else {
            self = Color(white: 0.5)
            return
        }
        self.init(
            red: Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >> 8) / 255,
            blue: Double(value & 0x0000FF) / 255
        )
    }
}

extension UIColor {
    convenience init(rgb: UInt) {
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
            blue: CGFloat(rgb & 0x0000FF) / 255,
            alpha: 1
        )
    }
}
