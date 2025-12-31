import Foundation

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return "Match System"
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        }
    }
}
