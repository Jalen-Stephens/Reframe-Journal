import Foundation

struct AutomaticThought: Codable, Identifiable, Hashable {
    let id: String
    var text: String
    var beliefBefore: Int
}

struct Emotion: Codable, Identifiable, Hashable {
    let id: String
    var label: String
    var intensityBefore: Int
    var intensityAfter: Int?
}

struct ThoughtOutcome: Codable, Hashable {
    var beliefAfter: Int
    var emotionsAfter: [String: Int]
    var reflection: String
    var isComplete: Bool
}

struct AdaptiveResponsesForThought: Codable, Hashable {
    var evidenceText: String
    var evidenceBelief: Int
    var alternativeText: String
    var alternativeBelief: Int
    var outcomeText: String
    var outcomeBelief: Int
    var friendText: String
    var friendBelief: Int
}

struct ThoughtRecord: Codable, Identifiable, Hashable {
    let id: String
    var createdAt: String
    var updatedAt: String
    var situationText: String
    var sensations: [String]
    var automaticThoughts: [AutomaticThought]
    var emotions: [Emotion]
    var thinkingStyles: [String]?
    var adaptiveResponses: [String: AdaptiveResponsesForThought]
    var outcomesByThought: [String: ThoughtOutcome]
    var beliefAfterMainThought: Int?
    var notes: String?

    static func empty(nowIso: String, id: String) -> ThoughtRecord {
        ThoughtRecord(
            id: id,
            createdAt: nowIso,
            updatedAt: nowIso,
            situationText: "",
            sensations: [],
            automaticThoughts: [],
            emotions: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: ""
        )
    }
}
