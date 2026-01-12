// File: ViewModels/UrgeEntryViewModel.swift
// ViewModel for urge entry editing

import Foundation
import SwiftData

@MainActor
final class UrgeEntryViewModel: ObservableObject {
    enum Section: Int, CaseIterable {
        case situation
        case sensations
        case emotions
        case urgeDescription
        case mindfulnessSkills
    }

    @Published var title: String
    @Published var occurredAt: Date
    @Published var situation: String
    @Published var sensations: String
    @Published var emotions: [EmotionItem]
    @Published var urgeDescription: String
    @Published var mindfulnessSkillsPracticed: [String]
    @Published var aiReframe: AIReframeResult?
    @Published var aiReframeCreatedAt: Date?
    @Published var aiReframeModel: String?
    @Published var aiReframePromptVersion: String?
    @Published var aiReframeDepth: AIReframeDepth?
    @Published var maxRevealedSection: Section
    @Published var isLoading: Bool = true

    private let entryId: String?
    private let store: JournalEntryStore
    private let thoughtUsage: ThoughtUsageService
    private var journalEntry: JournalEntry?
    private var autosaveTask: Task<Void, Never>?
    private var hasLoaded = false
    private var isTitleAutoManaged = true
    private var lastAutoTitle: String = ""
    private var didIncrementUsage = false
    private var isNewEntry = false
    private var recordId: String

    var currentRecordId: String {
        recordId
    }

    init(entryId: String?, modelContext: ModelContext, thoughtUsage: ThoughtUsageService) {
        self.entryId = entryId
        self.store = JournalEntryStore(modelContext: modelContext)
        self.thoughtUsage = thoughtUsage
        let empty = UrgeEntry.empty(now: Date())
        title = empty.title
        occurredAt = empty.occurredAt
        situation = empty.situation
        sensations = empty.sensations
        emotions = empty.emotions
        urgeDescription = empty.urgeDescription
        mindfulnessSkillsPracticed = empty.mindfulnessSkillsPracticed
        aiReframe = empty.aiReframe
        aiReframeCreatedAt = empty.aiReframeCreatedAt
        aiReframeModel = empty.aiReframeModel
        aiReframePromptVersion = empty.aiReframePromptVersion
        aiReframeDepth = empty.aiReframeDepth
        maxRevealedSection = .situation
        recordId = empty.recordId
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        defer { isLoading = false }
        guard let entryId else {
            isNewEntry = true
            return
        }
        do {
            guard let entry = try store.fetch(id: entryId) else {
                recordId = entryId
                isNewEntry = true
                return
            }
            guard entry.entryType == .urge, let urgeRecord = entry.urgeRecord else {
                recordId = entryId
                isNewEntry = true
                return
            }
            journalEntry = entry
            let urgeEntry = UrgeEntry(record: urgeRecord)
            apply(urgeEntry)
            recordId = entry.recordId
            isNewEntry = false
        } catch {
            isNewEntry = true
        }
    }

    func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            await self?.saveNow()
        }
    }
    
    func cancelAutosave() {
        autosaveTask?.cancel()
        autosaveTask = nil
    }

    func saveNow() async {
        let entry = buildEntry()
        do {
            if let existing = journalEntry {
                // Update existing entry
                let record = entry.applying(to: existing.urgeRecord)
                existing.urgeRecord = record
                existing.updatedAt = Date()
                existing.title = record.title
                existing.situationText = record.situationText
                existing.sensations = record.sensations
                existing.emotions = record.emotions
                try store.save()
            } else {
                // Only create new entry if it's not empty
                guard !isEntryEmpty(entry) else {
                    return
                }
                // Create new entry
                let record = entry.applying(to: nil)
                let newEntry = JournalEntry(from: record)
                try store.upsert(newEntry)
                journalEntry = try store.fetch(id: newEntry.recordId)
                recordId = newEntry.recordId
            }
            
            if isNewEntry && !didIncrementUsage, let entry = journalEntry {
                thoughtUsage.incrementTodayCount(recordId: entry.recordId, createdAt: DateUtils.isoString(from: entry.createdAt))
                didIncrementUsage = true
                isNewEntry = false
            }
        } catch {
#if DEBUG
            print("UrgeEntryViewModel save failed", error)
#endif
        }
    }
    
    func isEntryEmpty(_ entry: UrgeEntry? = nil) -> Bool {
        let entryToCheck = entry ?? buildEntry()
        let hasSituation = !entryToCheck.situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasEmotions = entryToCheck.emotions.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasUrge = !entryToCheck.urgeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSensations = !entryToCheck.sensations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return !hasSituation && !hasEmotions && !hasUrge && !hasSensations
    }
    
    func deleteIfEmpty() async {
        guard isEntryEmpty() else { return }
        guard let entry = journalEntry else { return }
        do {
            try store.delete(id: entry.recordId)
            journalEntry = nil
        } catch {
#if DEBUG
            print("UrgeEntryViewModel delete failed", error)
#endif
        }
    }

    func addEmotion() -> UUID {
        let item = EmotionItem(id: UUID(), name: "", intensity: 50)
        emotions.append(item)
        return item.id
    }

    func removeEmotion(id: UUID) {
        emotions.removeAll { $0.id == id }
        if emotions.isEmpty {
            _ = addEmotion()
        }
    }

    func updateTitleFromSituation() {
        guard isTitleAutoManaged else { return }
        let derived = deriveTitle(from: situation)
        lastAutoTitle = derived
        if title != derived {
            title = derived
        }
    }

    func markTitleEdited(_ newValue: String) {
        if newValue != lastAutoTitle {
            isTitleAutoManaged = false
        }
    }

    func reveal(_ section: Section) {
        if section.rawValue > maxRevealedSection.rawValue {
            maxRevealedSection = section
        }
    }

    func isSectionVisible(_ section: Section) -> Bool {
        section.rawValue <= maxRevealedSection.rawValue
    }

    func toggleMindfulnessSkill(_ skill: String) {
        if mindfulnessSkillsPracticed.contains(skill) {
            mindfulnessSkillsPracticed.removeAll { $0 == skill }
        } else {
            mindfulnessSkillsPracticed.append(skill)
        }
    }

    private func apply(_ entry: UrgeEntry) {
        recordId = entry.recordId
        title = entry.title
        occurredAt = entry.occurredAt
        situation = entry.situation
        sensations = entry.sensations
        emotions = entry.emotions.isEmpty ? [EmotionItem(id: UUID(), name: "", intensity: 50)] : entry.emotions
        urgeDescription = entry.urgeDescription
        mindfulnessSkillsPracticed = entry.mindfulnessSkillsPracticed
        aiReframe = entry.aiReframe
        aiReframeCreatedAt = entry.aiReframeCreatedAt
        aiReframeModel = entry.aiReframeModel
        aiReframePromptVersion = entry.aiReframePromptVersion
        aiReframeDepth = entry.aiReframeDepth
        maxRevealedSection = revealedSection(for: entry)
        isTitleAutoManaged = entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateTitleFromSituation()
    }

    private func buildEntry() -> UrgeEntry {
        UrgeEntry(
            id: UUID(uuidString: recordId.replacingOccurrences(of: "id_", with: "")) ?? UUID(),
            recordId: recordId,
            occurredAt: occurredAt,
            title: title,
            situation: situation,
            sensations: sensations,
            emotions: emotions,
            urgeDescription: urgeDescription,
            mindfulnessSkillsPracticed: mindfulnessSkillsPracticed,
            aiReframe: aiReframe,
            aiReframeCreatedAt: aiReframeCreatedAt,
            aiReframeModel: aiReframeModel,
            aiReframePromptVersion: aiReframePromptVersion,
            aiReframeDepth: aiReframeDepth,
            createdAt: journalEntry?.createdAt ?? occurredAt,
            updatedAt: Date()
        )
    }

    func currentRecordSnapshot() -> UrgeRecord {
        let entry = buildEntry()
        return entry.applying(to: journalEntry?.urgeRecord)
    }

    private func deriveTitle(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let firstLine = trimmed.split(separator: "\n", maxSplits: 1).first.map(String.init) ?? trimmed
        if firstLine.count > 40 {
            let index = firstLine.index(firstLine.startIndex, offsetBy: 40)
            return String(firstLine[..<index])
        }
        return firstLine
    }

    private func revealedSection(for entry: UrgeEntry) -> Section {
        let hasSensations = !entry.sensations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasEmotions = entry.emotions.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasUrge = !entry.urgeDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasSkills = !entry.mindfulnessSkillsPracticed.isEmpty
        if hasSkills {
            return .mindfulnessSkills
        }
        if hasUrge {
            return .urgeDescription
        }
        if hasEmotions {
            return .emotions
        }
        if hasSensations {
            return .sensations
        }
        return .situation
    }
}
