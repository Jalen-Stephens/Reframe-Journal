// File: ViewModels/ThoughtEntryViewModel.swift
// ViewModel for journal entry editing - updated for SwiftData

import Foundation
import SwiftData

@MainActor
final class ThoughtEntryViewModel: ObservableObject {
    enum Section: Int, CaseIterable {
        case situation
        case sensations
        case emotions
        case automaticThoughts
        case adaptiveResponses
        case outcome
    }

    enum Field: Hashable {
        case title
        case situation
        case sensations
        case emotionName(UUID)
        case automaticThought(String)
        case adaptiveResponseText(thoughtId: String, key: AdaptivePrompts.TextKey)
        case outcomeReflection(thoughtId: String)
    }

    @Published var title: String
    @Published var occurredAt: Date
    @Published var situation: String
    @Published var sensations: String
    @Published var emotions: [EmotionItem]
    @Published var automaticThoughts: [AutomaticThought]
    @Published var thinkingStyles: [String]
    @Published var adaptiveResponses: [String: AdaptiveResponsesForThought]
    @Published var outcomesByThought: [String: ThoughtOutcome]
    @Published var beliefAfterMainThought: Int?
    @Published var aiReframe: AIReframeResult?
    @Published var aiReframeCreatedAt: Date?
    @Published var aiReframeModel: String?
    @Published var aiReframePromptVersion: String?
    @Published var aiReframeDepth: AIReframeDepth?
    @Published var maxRevealedSection: Section
    @Published var scrollTarget: Section?
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
        let empty = ThoughtEntry.empty(now: Date())
        title = empty.title
        occurredAt = empty.occurredAt
        situation = empty.situation
        sensations = empty.sensations
        emotions = empty.emotions
        automaticThoughts = empty.automaticThoughts
        thinkingStyles = empty.thinkingStyles
        adaptiveResponses = empty.adaptiveResponses
        outcomesByThought = empty.outcomesByThought
        beliefAfterMainThought = empty.beliefAfterMainThought
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
            journalEntry = entry
            let thoughtEntry = ThoughtEntry(record: entry.toThoughtRecord())
            apply(thoughtEntry)
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
                existing.update(from: entry.applying(to: existing.toThoughtRecord()))
                existing.updatedAt = Date()
                try store.save()
            } else {
                // Only create new entry if it's not empty
                guard !isEntryEmpty(entry) else {
                    // If it's a new empty entry, don't save it
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
            // No need to post notification - SwiftData @Query handles reactivity automatically
        } catch {
#if DEBUG
            print("ThoughtEntryViewModel save failed", error)
#endif
        }
    }
    
    /// Check if an entry is empty (has no meaningful content)
    func isEntryEmpty(_ entry: ThoughtEntry? = nil) -> Bool {
        let entryToCheck = entry ?? buildEntry()
        
        // Check if situation text is empty or just whitespace
        let hasSituation = !entryToCheck.situation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Check if there are any emotions with names
        let hasEmotions = entryToCheck.emotions.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Check if there are any automatic thoughts with text
        let hasThoughts = entryToCheck.automaticThoughts.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // Check if there are sensations
        let hasSensations = !entryToCheck.sensations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Entry is empty if it has no situation, no emotions, no thoughts, and no sensations
        return !hasSituation && !hasEmotions && !hasThoughts && !hasSensations
    }
    
    /// Delete the current entry if it exists and is empty (for new entries that were never filled)
    func deleteIfEmpty() async {
        // Check if the entry is empty
        guard isEntryEmpty() else { return }
        
        // If it's a new entry that hasn't been saved yet, nothing to delete
        guard let entry = journalEntry else { return }
        
        // Delete the entry if it's empty
        do {
            try store.delete(id: entry.recordId)
            journalEntry = nil
        } catch {
#if DEBUG
            print("ThoughtEntryViewModel delete failed", error)
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

    func nextField(after field: Field) -> Field? {
        switch field {
        case .title:
            reveal(.situation)
            return .situation
        case .situation:
            reveal(.sensations)
            return .sensations
        case .sensations:
            reveal(.emotions)
            ensureEmotionRow()
            return emotions.first.map { .emotionName($0.id) }
        case .emotionName(let id):
            return handleEmotionSubmit(for: id)
        case .automaticThought(let id):
            return handleAutomaticThoughtSubmit(for: id)
        case .adaptiveResponseText(let thoughtId, let key):
            return nextAdaptiveResponseField(for: thoughtId, key: key)
        case .outcomeReflection:
            revealNextSection(from: .outcome)
            return nil
        }
    }

    func section(for field: Field) -> Section {
        switch field {
        case .title:
            return .situation
        case .situation:
            return .situation
        case .sensations:
            return .sensations
        case .emotionName:
            return .emotions
        case .automaticThought:
            return .automaticThoughts
        case .adaptiveResponseText:
            return .adaptiveResponses
        case .outcomeReflection:
            return .outcome
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

    func revealNextSection(from section: Section) {
        let nextIndex = section.rawValue + 1
        guard let next = Section(rawValue: nextIndex) else { return }
        reveal(next)
        scrollTarget = next
    }

    func insertNewline(into field: Field) {
        switch field {
        case .situation:
            situation = appendNewline(to: situation)
        case .sensations:
            sensations = appendNewline(to: sensations)
        case .adaptiveResponseText(let thoughtId, let key):
            updateAdaptiveResponse(thoughtId: thoughtId, key: key, value: appendNewline(to: adaptiveResponseValue(thoughtId: thoughtId, key: key)))
        case .outcomeReflection(let thoughtId):
            updateOutcomeReflection(thoughtId: thoughtId, value: appendNewline(to: outcomeReflection(for: thoughtId)))
        case .title, .emotionName, .automaticThought:
            break
        }
    }

    private func handleEmotionSubmit(for id: UUID) -> Field? {
        guard let index = emotions.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        let currentName = emotions[index].name.trimmingCharacters(in: .whitespacesAndNewlines)
        if index < emotions.count - 1 {
            return .emotionName(emotions[index + 1].id)
        }
        if !currentName.isEmpty {
            let newId = addEmotion()
            return .emotionName(newId)
        }
        revealNextSection(from: .emotions)
        ensureAutomaticThoughtRow()
        return automaticThoughts.first.map { .automaticThought($0.id) }
    }

    private func handleAutomaticThoughtSubmit(for id: String) -> Field? {
        guard let index = automaticThoughts.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        let currentText = automaticThoughts[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !currentText.isEmpty {
            revealNextSection(from: .automaticThoughts)
            return nil
        }
        revealNextSection(from: .automaticThoughts)
        return nil
    }

    private func nextAdaptiveResponseField(for thoughtId: String, key: AdaptivePrompts.TextKey) -> Field? {
        let prompts = adaptiveResponseKeys
        guard let index = prompts.firstIndex(of: key) else {
            return .outcomeReflection(thoughtId: thoughtId)
        }
        let nextIndex = prompts.index(after: index)
        guard prompts.indices.contains(nextIndex) else {
            reveal(.outcome)
            return .outcomeReflection(thoughtId: thoughtId)
        }
        return .adaptiveResponseText(thoughtId: thoughtId, key: prompts[nextIndex])
    }

    private func ensureEmotionRow() {
        if emotions.isEmpty {
            _ = addEmotion()
        }
    }

    private func ensureAutomaticThoughtRow() {
        if automaticThoughts.isEmpty {
            _ = addAutomaticThought()
        }
        if automaticThoughts.count > 1 {
            automaticThoughts = [automaticThoughts[0]]
        }
    }

    private func apply(_ entry: ThoughtEntry) {
        recordId = entry.recordId
        title = entry.title
        occurredAt = entry.occurredAt
        situation = entry.situation
        sensations = entry.sensations
        emotions = entry.emotions.isEmpty ? [EmotionItem(id: UUID(), name: "", intensity: 50)] : entry.emotions
        automaticThoughts = entry.automaticThoughts.isEmpty ? [] : [entry.automaticThoughts[0]]
        thinkingStyles = entry.thinkingStyles
        adaptiveResponses = entry.adaptiveResponses
        outcomesByThought = entry.outcomesByThought
        beliefAfterMainThought = entry.beliefAfterMainThought
        aiReframe = entry.aiReframe
        aiReframeCreatedAt = entry.aiReframeCreatedAt
        aiReframeModel = entry.aiReframeModel
        aiReframePromptVersion = entry.aiReframePromptVersion
        aiReframeDepth = entry.aiReframeDepth
        maxRevealedSection = revealedSection(for: entry)
        isTitleAutoManaged = entry.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        updateTitleFromSituation()
    }

    private func buildEntry() -> ThoughtEntry {
        ThoughtEntry(
            id: UUID(uuidString: recordId.replacingOccurrences(of: "id_", with: "")) ?? UUID(),
            recordId: recordId,
            occurredAt: occurredAt,
            title: title,
            situation: situation,
            sensations: sensations,
            emotions: emotions,
            automaticThoughts: automaticThoughts,
            thinkingStyles: thinkingStyles,
            adaptiveResponses: adaptiveResponses,
            outcomesByThought: outcomesByThought,
            beliefAfterMainThought: beliefAfterMainThought,
            aiReframe: aiReframe,
            aiReframeCreatedAt: aiReframeCreatedAt,
            aiReframeModel: aiReframeModel,
            aiReframePromptVersion: aiReframePromptVersion,
            aiReframeDepth: aiReframeDepth,
            createdAt: journalEntry?.createdAt ?? occurredAt,
            updatedAt: Date()
        )
    }

    func currentRecordSnapshot() -> ThoughtRecord {
        let entry = buildEntry()
        return entry.applying(to: journalEntry?.toThoughtRecord())
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

    private func appendNewline(to text: String) -> String {
        text + "\n"
    }

    private func revealedSection(for entry: ThoughtEntry) -> Section {
        let hasSensations = !entry.sensations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasEmotions = entry.emotions.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasThoughts = entry.automaticThoughts.contains { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let hasAdaptive = !entry.adaptiveResponses.isEmpty
        let hasOutcome = !entry.outcomesByThought.isEmpty || entry.beliefAfterMainThought != nil
        if hasOutcome {
            return .outcome
        }
        if hasAdaptive {
            return .adaptiveResponses
        }
        if hasThoughts {
            return .automaticThoughts
        }
        if hasEmotions {
            return .emotions
        }
        if hasSensations {
            return .sensations
        }
        return .situation
    }

    private var adaptiveResponseKeys: [AdaptivePrompts.TextKey] {
        AdaptivePrompts.all.map { $0.textKey }
    }

    func addAutomaticThought() -> String {
        if let existing = automaticThoughts.first {
            return existing.id
        }
        let id = Identifiers.generateId()
        automaticThoughts.append(AutomaticThought(id: id, text: "", beliefBefore: 50))
        return id
    }

    func removeAutomaticThought(id: String) {
        automaticThoughts.removeAll { $0.id == id }
        adaptiveResponses[id] = nil
        outcomesByThought[id] = nil
        if automaticThoughts.isEmpty {
            _ = addAutomaticThought()
        }
    }

    func updateAdaptiveResponse(thoughtId: String, key: AdaptivePrompts.TextKey, value: String) {
        var response = adaptiveResponses[thoughtId] ?? AdaptiveResponsesForThought(
            evidenceText: "",
            evidenceBelief: 0,
            alternativeText: "",
            alternativeBelief: 0,
            outcomeText: "",
            outcomeBelief: 0,
            friendText: "",
            friendBelief: 0
        )
        switch key {
        case .evidenceText:
            response.evidenceText = value
        case .alternativeText:
            response.alternativeText = value
        case .outcomeText:
            response.outcomeText = value
        case .friendText:
            response.friendText = value
        }
        adaptiveResponses[thoughtId] = response
    }

    func adaptiveResponseValue(thoughtId: String, key: AdaptivePrompts.TextKey) -> String {
        guard let response = adaptiveResponses[thoughtId] else { return "" }
        switch key {
        case .evidenceText:
            return response.evidenceText
        case .alternativeText:
            return response.alternativeText
        case .outcomeText:
            return response.outcomeText
        case .friendText:
            return response.friendText
        }
    }

    func ensureOutcome(for thoughtId: String, beliefBefore: Int) -> ThoughtOutcome {
        if let existing = outcomesByThought[thoughtId] {
            return existing
        }
        let outcome = ThoughtOutcome(beliefAfter: beliefBefore, emotionsAfter: [:], reflection: "", isComplete: false)
        outcomesByThought[thoughtId] = outcome
        return outcome
    }

    func updateOutcomeReflection(thoughtId: String, value: String) {
        let thought = automaticThoughts.first { $0.id == thoughtId }
        let belief = thought?.beliefBefore ?? 50
        var outcome = ensureOutcome(for: thoughtId, beliefBefore: belief)
        outcome.reflection = value
        outcomesByThought[thoughtId] = outcome
    }

    func outcomeReflection(for thoughtId: String) -> String {
        outcomesByThought[thoughtId]?.reflection ?? ""
    }
}
