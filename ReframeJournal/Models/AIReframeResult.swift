import Foundation

struct AIReframeResult: Codable, Equatable, Hashable {
    let reframeSummary: String
    let balancedThought: String?
    let suggestions: [String]
    let validation: String

    static func fallback(from rawText: String) -> AIReframeResult {
        AIReframeResult(
            reframeSummary: rawText,
            balancedThought: nil,
            suggestions: [],
            validation: ""
        )
    }

    enum CodingKeys: String, CodingKey {
        case reframeSummary = "reframe_summary"
        case balancedThought = "balanced_thought"
        case suggestions
        case validation
    }
}
