import SwiftUI

enum ThemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:
            return "System (Default)"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }

    var helper: String? {
        switch self {
        case .system:
            return "Matches your device setting"
        default:
            return nil
        }
    }
}

struct ThemeTokens {
    let background: Color
    let card: Color
    let textPrimary: Color
    let textSecondary: Color
    let placeholder: Color
    let border: Color
    let muted: Color
    let accent: Color
    let onAccent: Color
}

final class ThemeManager: ObservableObject {
    @AppStorage("themePreference") private var storedPreference: String = ThemePreference.system.rawValue

    @Published var resolvedScheme: ColorScheme = .light
    @Published var themePreference: ThemePreference = .system {
        didSet {
            storedPreference = themePreference.rawValue
        }
    }

    init() {
        themePreference = ThemePreference(rawValue: storedPreference) ?? .system
    }

    var theme: ThemeTokens {
        switch resolvedScheme {
        case .dark:
            return ThemeTokens(
                background: Color(hex: "#0E0E0E"),
                card: Color(hex: "#1A1A1A"),
                textPrimary: Color(hex: "#F5F5F5"),
                textSecondary: Color(hex: "#BDBDBD"),
                placeholder: Color.white.opacity(0.6),
                border: Color(hex: "#2A2A2A"),
                muted: Color(hex: "#2F2F2F"),
                accent: Color(hex: "#4AC07A"),
                onAccent: Color(hex: "#0E0E0E")
            )
        default:
            return ThemeTokens(
                background: Color(hex: "#FAFAFA"),
                card: Color(hex: "#FFFFFF"),
                textPrimary: Color(hex: "#1F1F1F"),
                textSecondary: Color(hex: "#5E5E5E"),
                placeholder: Color(hex: "#8A8A8A"),
                border: Color(hex: "#E3E3E3"),
                muted: Color(hex: "#EFEFEF"),
                accent: Color(hex: "#2F2F2F"),
                onAccent: Color(hex: "#FFFFFF")
            )
        }
    }

    func preferredColorScheme() -> ColorScheme? {
        switch themePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
