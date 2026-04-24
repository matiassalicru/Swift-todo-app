import SwiftUI

enum AppTheme {
    // Brand — dynamic accent, resolved from ThemeManager
    static var violet: Color { ThemeManager.shared.accentColor }
    static let success = Color(red: 0.25, green: 0.80, blue: 0.55)

    // Text
    static let text = Color(NSColor.labelColor)
    static let textSecondary = Color(NSColor.secondaryLabelColor)

    // Glass
    static let glassBorder = Color.primary.opacity(0.12)
    static let glassShadow = Color.black.opacity(0.08)

    // Separators
    static let border = Color(NSColor.separatorColor)
}
