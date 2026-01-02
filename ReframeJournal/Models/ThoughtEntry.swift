import Foundation

struct ThoughtEntry: Codable, Identifiable, Hashable {
    let id: UUID
    let recordId: String
    var occurredAt: Date
    var title: String
    var situation: String
    var sensations: String
    var emotions: [EmotionItem]
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func empty(now: Date = Date()) -> ThoughtEntry {
        let recordId = Identifiers.generateId()
        let uuid = UUID(uuidString: recordId.replacingOccurrences(of: "id_", with: "")) ?? UUID()
        return ThoughtEntry(
            id: uuid,
            recordId: recordId,
            occurredAt: now,
            title: "",
            situation: "",
            sensations: "",
            emotions: [EmotionItem(id: UUID(), name: "", intensity: 50)],
            createdAt: now,
            updatedAt: now
        )
    }

    init(record: ThoughtRecord) {
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
        createdAt = createdDate
        updatedAt = updatedDate
    }

    func applying(to record: ThoughtRecord?) -> ThoughtRecord {
        let nowIso = DateUtils.nowIso()
        let createdIso = DateUtils.isoString(from: occurredAt)
        let baseRecord = record ?? ThoughtRecord.empty(nowIso: createdIso, id: recordId)
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

        return ThoughtRecord(
            id: baseRecord.id,
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            createdAt: createdIso,
            updatedAt: nowIso,
            situationText: situation,
            sensations: splitSensations(sensations),
            automaticThoughts: baseRecord.automaticThoughts,
            emotions: emotionItems,
            thinkingStyles: baseRecord.thinkingStyles,
            adaptiveResponses: baseRecord.adaptiveResponses,
            outcomesByThought: baseRecord.outcomesByThought,
            beliefAfterMainThought: baseRecord.beliefAfterMainThought,
            notes: baseRecord.notes,
            aiReframe: baseRecord.aiReframe,
            aiReframeCreatedAt: baseRecord.aiReframeCreatedAt,
            aiReframeModel: baseRecord.aiReframeModel,
            aiReframePromptVersion: baseRecord.aiReframePromptVersion,
            aiReframeDepth: baseRecord.aiReframeDepth
        )
    }

    private func splitSensations(_ value: String) -> [String] {
        value
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
