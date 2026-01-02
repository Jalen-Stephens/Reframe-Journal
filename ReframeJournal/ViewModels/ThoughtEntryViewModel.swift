import Foundation

@MainActor
final class ThoughtEntryViewModel: ObservableObject {
    enum Section: Int, CaseIterable {
        case situation
        case sensations
        case emotions
        case automaticThoughts
        case evidence
        case balanced
    }

    enum Field: Hashable {
        case title
        case situation
        case sensations
        case emotionName(UUID)
    }

    @Published var title: String
    @Published var occurredAt: Date
    @Published var situation: String
    @Published var sensations: String
    @Published var emotions: [EmotionItem]
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
                thoughtUsage.incrementTodayCount()
                didIncrementUsage = true
                isNewEntry = false
            }
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
        case .title, .emotionName:
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
        return nil
    }

    private func ensureEmotionRow() {
        if emotions.isEmpty {
            _ = addEmotion()
        }
    }

    private func apply(_ entry: ThoughtEntry) {
        recordId = entry.recordId
        title = entry.title
        occurredAt = entry.occurredAt
        situation = entry.situation
        sensations = entry.sensations
        emotions = entry.emotions.isEmpty ? [EmotionItem(id: UUID(), name: "", intensity: 50)] : entry.emotions
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
            createdAt: baseRecord.flatMap { DateUtils.parseIso($0.createdAt) } ?? occurredAt,
            updatedAt: Date()
        )
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
        if hasEmotions {
            return .emotions
        }
        if hasSensations {
            return .sensations
        }
        return .situation
    }
}
