import Foundation

struct EmotionItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var intensity: Int
}
