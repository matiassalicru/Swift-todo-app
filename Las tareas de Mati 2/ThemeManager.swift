import SwiftUI
import Combine

enum AccentColor: String, CaseIterable, Identifiable {
    case violet
    case blue
    case teal
    case mint
    case green
    case orange
    case pink
    case red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .violet: return Color(red: 0.62, green: 0.52, blue: 0.98)
        case .blue:   return Color(red: 0.30, green: 0.55, blue: 0.98)
        case .teal:   return Color(red: 0.24, green: 0.72, blue: 0.78)
        case .mint:   return Color(red: 0.30, green: 0.82, blue: 0.66)
        case .green:  return Color(red: 0.32, green: 0.76, blue: 0.44)
        case .orange: return Color(red: 0.98, green: 0.60, blue: 0.30)
        case .pink:   return Color(red: 0.96, green: 0.44, blue: 0.66)
        case .red:    return Color(red: 0.94, green: 0.38, blue: 0.42)
        }
    }

    var displayName: String {
        switch self {
        case .violet: return "Violeta"
        case .blue:   return "Azul"
        case .teal:   return "Agua"
        case .mint:   return "Menta"
        case .green:  return "Verde"
        case .orange: return "Naranja"
        case .pink:   return "Rosa"
        case .red:    return "Rojo"
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private static let storageKey = "accentColorName"

    @Published var accent: AccentColor {
        didSet {
            UserDefaults.standard.set(accent.rawValue, forKey: Self.storageKey)
        }
    }

    var accentColor: Color { accent.color }

    private init() {
        let storedValue = UserDefaults.standard.string(forKey: Self.storageKey)
        self.accent = AccentColor(rawValue: storedValue ?? "") ?? .violet
    }
}
