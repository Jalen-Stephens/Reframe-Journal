import Foundation

struct UrgeEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let recordId: String
    var occurredAt: Date
    var title: String
    var situation: String
    var sensations: String
    var emotions: [EmotionItem]
    var urgeDescription: String
    var mindfulnessSkillsPracticed: [String]
    var aiReframe: AIReframeResult?
    var aiReframeCreatedAt: Date?
    var aiReframeModel: String?
    var aiReframePromptVersion: String?
    var aiReframeDepth: AIReframeDepth?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID,
        recordId: String,
        occurredAt: Date,
        title: String,
        situation: String,
        sensations: String,
        emotions: [EmotionItem],
        urgeDescription: String,
        mindfulnessSkillsPracticed: [String],
        aiReframe: AIReframeResult?,
        aiReframeCreatedAt: Date?,
        aiReframeModel: String?,
        aiReframePromptVersion: String?,
        aiReframeDepth: AIReframeDepth?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.recordId = recordId
        self.occurredAt = occurredAt
        self.title = title
        self.situation = situation
        self.sensations = sensations
        self.emotions = emotions
        self.urgeDescription = urgeDescription
        self.mindfulnessSkillsPracticed = mindfulnessSkillsPracticed
        self.aiReframe = aiReframe
        self.aiReframeCreatedAt = aiReframeCreatedAt
        self.aiReframeModel = aiReframeModel
        self.aiReframePromptVersion = aiReframePromptVersion
        self.aiReframeDepth = aiReframeDepth
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func empty(now: Date = Date()) -> UrgeEntry {
        let recordId = Identifiers.generateId()
        let uuid = UUID(uuidString: recordId.replacingOccurrences(of: "id_", with: "")) ?? UUID()
        return UrgeEntry(
            id: uuid,
            recordId: recordId,
            occurredAt: now,
            title: "",
            situation: "",
            sensations: "",
            emotions: [EmotionItem(id: UUID(), name: "", intensity: 50)],
            urgeDescription: "",
            mindfulnessSkillsPracticed: [],
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: now,
            updatedAt: now
        )
    }

    init(record: UrgeRecord) {
        let uuid = UUID(uuidString: record.id.replacingOccurrences(of: "id_", with: "")) ?? UUID()
        let createdDate = DateUtils.parseIso(record.createdAt) ?? Date()
        let updatedDate = DateUtils.parseIso(record.updatedAt) ?? createdDate
        id = uuid
        recordId = record.id
        occurredAt = DateUtils.parseIso(record.createdAt) ?? Date()
        title = record.title ?? ""
        situation = record.situationText
        sensations = record.sensations.joined(separator: "\n")
        emotions = record.emotions.map { item in
            let emotionId = UUID(uuidString: item.id) ?? UUID()
            return EmotionItem(id: emotionId, name: item.label, intensity: item.intensityBefore)
        }
        urgeDescription = record.urgeDescription
        mindfulnessSkillsPracticed = record.mindfulnessSkillsPracticed ?? []
        aiReframe = record.aiReframe
        aiReframeCreatedAt = record.aiReframeCreatedAt
        aiReframeModel = record.aiReframeModel
        aiReframePromptVersion = record.aiReframePromptVersion
        aiReframeDepth = record.aiReframeDepth
        createdAt = createdDate
        updatedAt = updatedDate
    }

    func applying(to record: UrgeRecord?) -> UrgeRecord {
        let nowIso = DateUtils.nowIso()
        let createdIso = DateUtils.isoString(from: occurredAt)
        let baseRecord = record ?? UrgeRecord.empty(nowIso: createdIso, id: recordId)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let emotionItems = emotions
            .map { item in
                Emotion(
                    id: item.id.uuidString,
                    label: item.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    intensityBefore: Metrics.clampPercent(item.intensity),
                    intensityAfter: nil
                )
            }
            .filter { !$0.label.isEmpty }

        return UrgeRecord(
            id: baseRecord.id,
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            createdAt: createdIso,
            updatedAt: nowIso,
            situationText: situation,
            sensations: splitSensations(sensations),
            emotions: emotionItems,
            urgeDescription: urgeDescription,
            mindfulnessSkillsPracticed: mindfulnessSkillsPracticed,
            notes: baseRecord.notes,
            aiReframe: aiReframe,
            aiReframeCreatedAt: aiReframeCreatedAt,
            aiReframeModel: aiReframeModel,
            aiReframePromptVersion: aiReframePromptVersion,
            aiReframeDepth: aiReframeDepth
        )
    }

    private func splitSensations(_ value: String) -> [String] {
        value
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
