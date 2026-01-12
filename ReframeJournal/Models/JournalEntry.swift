// File: Models/JournalEntry.swift
// SwiftData model for journal entries - replaces JSON-based ThoughtRecord persistence

import Foundation
import SwiftData

// MARK: - Main SwiftData Model

@Model
final class JournalEntry {
    // MARK: - Primary Key
    
    /// Unique identifier for the entry
    @Attribute(.unique) var recordId: String
    
    // MARK: - Core Fields
    
    var title: String?
    var createdAt: Date
    var updatedAt: Date
    var situationText: String
    var sensations: [String]
    
    // MARK: - Structured Data (stored as Codable)
    
    /// Automatic thoughts captured during the entry
    var automaticThoughtsData: Data?
    
    /// Emotions with intensity ratings
    var emotionsData: Data?
    
    /// Optional thinking styles identified
    var thinkingStyles: [String]?
    
    /// Adaptive responses keyed by thought ID
    var adaptiveResponsesData: Data?
    
    /// Outcomes keyed by thought ID
    var outcomesByThoughtData: Data?
    
    /// Main thought belief after reframing
    var beliefAfterMainThought: Int?
    
    /// Optional notes
    var notes: String?
    
    // MARK: - AI Reframe Fields
    
    var aiReframeData: Data?
    var aiReframeCreatedAt: Date?
    var aiReframeModel: String?
    var aiReframePromptVersion: String?
    var aiReframeDepthRaw: String?
    
    // MARK: - Entry Type and Status
    
    /// Type of entry (thought or urge)
    var entryTypeRaw: String = "thought"
    
    /// Optional status for the entry (reviewed with therapist, revisit, etc.)
    var entryStatusRaw: String?
    
    // MARK: - Urge Record Data (stored as Codable)
    
    /// Urge record data (for urge entries only)
    var urgeRecordData: Data?
    
    // MARK: - Draft Flag
    
    /// Indicates this is a draft entry (not yet finalized)
    var isDraft: Bool
    
    // MARK: - Computed Properties (Codable Accessors)
    
    var automaticThoughts: [AutomaticThought] {
        get {
            guard let data = automaticThoughtsData else { return [] }
            return (try? JSONDecoder().decode([AutomaticThought].self, from: data)) ?? []
        }
        set {
            automaticThoughtsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var emotions: [Emotion] {
        get {
            guard let data = emotionsData else { return [] }
            return (try? JSONDecoder().decode([Emotion].self, from: data)) ?? []
        }
        set {
            emotionsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var adaptiveResponses: [String: AdaptiveResponsesForThought] {
        get {
            guard let data = adaptiveResponsesData else { return [:] }
            return (try? JSONDecoder().decode([String: AdaptiveResponsesForThought].self, from: data)) ?? [:]
        }
        set {
            adaptiveResponsesData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var outcomesByThought: [String: ThoughtOutcome] {
        get {
            guard let data = outcomesByThoughtData else { return [:] }
            return (try? JSONDecoder().decode([String: ThoughtOutcome].self, from: data)) ?? [:]
        }
        set {
            outcomesByThoughtData = try? JSONEncoder().encode(newValue)
        }
    }
    
    var aiReframe: AIReframeResult? {
        get {
            guard let data = aiReframeData else { return nil }
            return try? JSONDecoder().decode(AIReframeResult.self, from: data)
        }
        set {
            aiReframeData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
    
    var aiReframeDepth: AIReframeDepth? {
        get {
            guard let raw = aiReframeDepthRaw else { return nil }
            return AIReframeDepth(rawValue: raw)
        }
        set {
            aiReframeDepthRaw = newValue?.rawValue
        }
    }
    
    var entryType: EntryType {
        get {
            EntryType(rawValue: entryTypeRaw) ?? .thought
        }
        set {
            entryTypeRaw = newValue.rawValue
        }
    }
    
    var entryStatus: EntryStatus? {
        get {
            guard let raw = entryStatusRaw else { return nil }
            return EntryStatus(rawValue: raw)
        }
        set {
            entryStatusRaw = newValue?.rawValue
        }
    }
    
    var urgeRecord: UrgeRecord? {
        get {
            guard let data = urgeRecordData else { return nil }
            return try? JSONDecoder().decode(UrgeRecord.self, from: data)
        }
        set {
            urgeRecordData = newValue.flatMap { try? JSONEncoder().encode($0) }
        }
    }
    
    // MARK: - Initialization
    
    init(
        recordId: String = Identifiers.generateId(),
        title: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        situationText: String = "",
        sensations: [String] = [],
        automaticThoughts: [AutomaticThought] = [],
        emotions: [Emotion] = [],
        thinkingStyles: [String]? = nil,
        adaptiveResponses: [String: AdaptiveResponsesForThought] = [:],
        outcomesByThought: [String: ThoughtOutcome] = [:],
        beliefAfterMainThought: Int? = nil,
        notes: String? = nil,
        aiReframe: AIReframeResult? = nil,
        aiReframeCreatedAt: Date? = nil,
        aiReframeModel: String? = nil,
        aiReframePromptVersion: String? = nil,
        aiReframeDepth: AIReframeDepth? = nil,
        isDraft: Bool = false,
        entryType: EntryType = .thought,
        entryStatus: EntryStatus? = nil,
        urgeRecord: UrgeRecord? = nil
    ) {
        self.recordId = recordId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.situationText = situationText
        self.sensations = sensations
        self.thinkingStyles = thinkingStyles
        self.beliefAfterMainThought = beliefAfterMainThought
        self.notes = notes
        self.aiReframeCreatedAt = aiReframeCreatedAt
        self.aiReframeModel = aiReframeModel
        self.aiReframePromptVersion = aiReframePromptVersion
        self.aiReframeDepthRaw = aiReframeDepth?.rawValue
        self.isDraft = isDraft
        self.entryTypeRaw = entryType.rawValue
        self.entryStatusRaw = entryStatus?.rawValue
        
        // Set encoded data
        self.automaticThoughtsData = try? JSONEncoder().encode(automaticThoughts)
        self.emotionsData = try? JSONEncoder().encode(emotions)
        self.adaptiveResponsesData = try? JSONEncoder().encode(adaptiveResponses)
        self.outcomesByThoughtData = try? JSONEncoder().encode(outcomesByThought)
        self.aiReframeData = aiReframe.flatMap { try? JSONEncoder().encode($0) }
        self.urgeRecordData = urgeRecord.flatMap { try? JSONEncoder().encode($0) }
    }
    
    // MARK: - Convenience Factory
    
    static func empty(now: Date = Date(), id: String? = nil) -> JournalEntry {
        JournalEntry(
            recordId: id ?? Identifiers.generateId(),
            createdAt: now,
            updatedAt: now
        )
    }
}

// MARK: - Conversion Helpers

extension JournalEntry {
    /// Creates a JournalEntry from an existing ThoughtRecord
    convenience init(from record: ThoughtRecord) {
        let createdDate = DateUtils.parseIso(record.createdAt) ?? Date()
        let updatedDate = DateUtils.parseIso(record.updatedAt) ?? createdDate
        
        self.init(
            recordId: record.id,
            title: record.title,
            createdAt: createdDate,
            updatedAt: updatedDate,
            situationText: record.situationText,
            sensations: record.sensations,
            automaticThoughts: record.automaticThoughts,
            emotions: record.emotions,
            thinkingStyles: record.thinkingStyles,
            adaptiveResponses: record.adaptiveResponses,
            outcomesByThought: record.outcomesByThought,
            beliefAfterMainThought: record.beliefAfterMainThought,
            notes: record.notes,
            aiReframe: record.aiReframe,
            aiReframeCreatedAt: record.aiReframeCreatedAt,
            aiReframeModel: record.aiReframeModel,
            aiReframePromptVersion: record.aiReframePromptVersion,
            aiReframeDepth: record.aiReframeDepth,
            isDraft: false,
            entryType: .thought
        )
    }
    
    /// Creates a JournalEntry from an existing UrgeRecord
    convenience init(from record: UrgeRecord) {
        let createdDate = DateUtils.parseIso(record.createdAt) ?? Date()
        let updatedDate = DateUtils.parseIso(record.updatedAt) ?? createdDate
        
        self.init(
            recordId: record.id,
            title: record.title,
            createdAt: createdDate,
            updatedAt: updatedDate,
            situationText: record.situationText,
            sensations: record.sensations,
            isDraft: false,
            entryType: .urge,
            urgeRecord: record
        )
    }
    
    /// Converts to a ThoughtRecord for compatibility with existing code
    func toThoughtRecord() -> ThoughtRecord {
        ThoughtRecord(
            id: recordId,
            title: title,
            createdAt: DateUtils.isoString(from: createdAt),
            updatedAt: DateUtils.isoString(from: updatedAt),
            situationText: situationText,
            sensations: sensations,
            automaticThoughts: automaticThoughts,
            emotions: emotions,
            thinkingStyles: thinkingStyles,
            adaptiveResponses: adaptiveResponses,
            outcomesByThought: outcomesByThought,
            beliefAfterMainThought: beliefAfterMainThought,
            notes: notes,
            aiReframe: aiReframe,
            aiReframeCreatedAt: aiReframeCreatedAt,
            aiReframeModel: aiReframeModel,
            aiReframePromptVersion: aiReframePromptVersion,
            aiReframeDepth: aiReframeDepth
        )
    }
    
    /// Updates this entry from a ThoughtRecord
    func update(from record: ThoughtRecord) {
        title = record.title
        updatedAt = DateUtils.parseIso(record.updatedAt) ?? Date()
        situationText = record.situationText
        sensations = record.sensations
        automaticThoughts = record.automaticThoughts
        emotions = record.emotions
        thinkingStyles = record.thinkingStyles
        adaptiveResponses = record.adaptiveResponses
        outcomesByThought = record.outcomesByThought
        beliefAfterMainThought = record.beliefAfterMainThought
        notes = record.notes
        aiReframe = record.aiReframe
        aiReframeCreatedAt = record.aiReframeCreatedAt
        aiReframeModel = record.aiReframeModel
        aiReframePromptVersion = record.aiReframePromptVersion
        aiReframeDepth = record.aiReframeDepth
    }
}

// MARK: - Completion Status

extension JournalEntry {
    /// Completion is inferred from saved AI reframe or a completed outcome step (for thoughts) or mindfulness practice (for urges).
    var completionStatus: EntryCompletionStatus {
        if aiReframe != nil {
            return .complete
        }
        switch entryType {
        case .thought:
            if outcomesByThought.values.contains(where: { $0.isComplete }) {
                return .complete
            }
        case .urge:
            if let urgeRecord = urgeRecord, let skills = urgeRecord.mindfulnessSkillsPracticed, !skills.isEmpty {
                return .complete
            }
        }
        return .draft
    }
    
    /// Converts to an UrgeRecord if this is an urge entry
    func toUrgeRecord() -> UrgeRecord? {
        guard entryType == .urge, let urgeRecord = urgeRecord else { return nil }
        return urgeRecord
    }
}
