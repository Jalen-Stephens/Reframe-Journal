import Foundation

enum Identifiers {
    static func generateId() -> String {
        "id_\(UUID().uuidString)"
    }
}
