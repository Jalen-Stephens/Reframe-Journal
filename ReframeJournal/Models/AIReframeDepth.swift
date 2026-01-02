import Foundation

enum AIReframeDepth: String, Codable, CaseIterable, Identifiable {
    case quick
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick: return "Quick"
        case .deep: return "Deep"
        }
    }

    var promptLabel: String {
        switch self {
        case .quick: return "Quick"
        case .deep: return "Deep"
        }
    }
}
