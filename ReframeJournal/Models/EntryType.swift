import Foundation

enum EntryType: String, Codable, CaseIterable {
    case thought
    case urge
    
    var displayName: String {
        switch self {
        case .thought:
            return "Thought"
        case .urge:
            return "Urge"
        }
    }
}
