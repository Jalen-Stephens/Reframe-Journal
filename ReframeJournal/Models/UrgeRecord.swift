import Foundation

struct UrgeRecord: Codable, Identifiable, Hashable {
    let id: String
    var title: String?
    var createdAt: String
    var updatedAt: String
    var situationText: String
    var sensations: [String]
    var emotions: [Emotion]
    var urgeDescription: String
    var mindfulnessSkillsPracticed: [String]?
    var notes: String?
    var aiReframe: AIReframeResult?
    var aiReframeCreatedAt: Date?
    var aiReframeModel: String?
    var aiReframePromptVersion: String?
    var aiReframeDepth: AIReframeDepth?
    
    static func empty(nowIso: String, id: String) -> UrgeRecord {
        UrgeRecord(
            id: id,
            title: nil,
            createdAt: nowIso,
            updatedAt: nowIso,
            situationText: "",
            sensations: [],
            emotions: [],
            urgeDescription: "",
            mindfulnessSkillsPracticed: [],
            notes: "",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
    }
}

extension UrgeRecord {
    /// Completion is inferred from saved AI reframe or completed mindfulness practice.
    var completionStatus: EntryCompletionStatus {
        if aiReframe != nil {
            return .complete
        }
        if let skills = mindfulnessSkillsPracticed, !skills.isEmpty {
            return .complete
        }
        return .draft
    }
}
