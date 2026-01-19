import Foundation

enum EntryType: String, Codable, CaseIterable {
    case thought
    
    var displayName: String {
        return "Thought"
    }
}
