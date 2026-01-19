import Foundation

enum EntryStatus: String, Codable, CaseIterable {
    case reviewedWithTherapist
    case revisit
    
    var displayName: String {
        switch self {
        case .reviewedWithTherapist:
            return "Reviewed with therapist"
        case .revisit:
            return "Revisit"
        }
    }
    
    var icon: String {
        switch self {
        case .reviewedWithTherapist:
            return "checkmark.circle.fill"
        case .revisit:
            return "arrow.clockwise.circle.fill"
        }
    }
}
