import Foundation

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
    private let store: ThoughtEntryStore
    private let thoughtUsage: ThoughtUsageService
    private var baseRecord: ThoughtRecord?
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

    init(entryId: String?, store: ThoughtEntryStore, thoughtUsage: ThoughtUsageService) {
        self.entryId = entryId
        self.store = store
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
            guard let record = try await store.fetchRecord(id: entryId) else {
                recordId = entryId
                isNewEntry = true
                return
            }
            baseRecord = record
            let entry = ThoughtEntry(record: record)
            apply(entry)
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

    func saveNow() async {
        let entry = buildEntry()
        do {
            let updated = try await store.upsert(entry, baseRecord: baseRecord)
            baseRecord = updated
            recordId = updated.id
            if isNewEntry && !didIncrementUsage {
                thoughtUsage.incrementTodayCount(recordId: updated.id, createdAt: updated.createdAt)
                didIncrementUsage = true
                isNewEntry = false
            }
            // Post notification so HomeView can refresh its list
            NotificationCenter.default.post(name: .thoughtEntrySaved, object: nil)
        } catch {
#if DEBUG
            print("ThoughtEntryViewModel save failed", error)
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
            createdAt: baseRecord.flatMap { DateUtils.parseIso($0.createdAt) } ?? occurredAt,
            updatedAt: Date()
        )
    }

    func currentRecordSnapshot() -> ThoughtRecord {
        let entry = buildEntry()
        return entry.applying(to: baseRecord)
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
