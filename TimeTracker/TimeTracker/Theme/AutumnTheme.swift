import SwiftUI

/// Warm, calm palette — "Maple Glow / Falling Leaf" without literal seasonal
/// decoration. Every token is defined for both light and dark.
enum AutumnTheme {
    static let background     = Color(light: 0xF7F1E6, dark: 0x1E1A17)
    static let surface        = Color(light: 0xFFFBF3, dark: 0x2A2521)
    static let surfaceRaised   = Color(light: 0xFFFFFF, dark: 0x342D27)
    static let primaryText     = Color(light: 0x2E2620, dark: 0xF2E9DC)
    static let secondaryText   = Color(light: 0x82705C, dark: 0xB6A794)
    static let accent          = Color(light: 0xB5643C, dark: 0xD3854F)
    static let accentSoft      = Color(light: 0xE7CDAF, dark: 0x5A4636)
    static let hairline        = Color(light: 0xE9DECB, dark: 0x3D352E)
    static let captureCore     = Color(light: 0xC96F3F, dark: 0xD3854F)
    static let captureRim      = Color(light: 0xEAD7BE, dark: 0x463A30)

    /// Coherent warm set for custom activities, plus two muted cool accents so
    /// a dozen activities stay distinguishable.
    static let activityPalette: [String] = [
        "#B5643C", "#C6522E", "#D08C34", "#9C6B3F",
        "#C98A5B", "#8A6A55", "#A9743E", "#8C5A3C",
        "#BE7A45", "#6F5B7A", "#7A8450", "#4F6D6A"
    ]
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
