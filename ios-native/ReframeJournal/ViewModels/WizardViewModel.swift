import Foundation

@MainActor
final class WizardViewModel: ObservableObject {
    @Published var draft: ThoughtRecord
    @Published var isEditing: Bool = false

    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
        let now = DateUtils.nowIso()
        self.draft = ThoughtRecord.empty(nowIso: now, id: Identifiers.generateId())
        Task { await loadDraft() }
    }

    func resetDraft() {
        let now = DateUtils.nowIso()
        draft = ThoughtRecord.empty(nowIso: now, id: Identifiers.generateId())
        isEditing = false
    }

    func setDraft(_ record: ThoughtRecord, isEditing: Bool) {
        draft = record
        self.isEditing = isEditing
    }

    func persistDraft(_ record: ThoughtRecord? = nil) async {
        let base = record ?? draft
        let updated = ThoughtRecord(
            id: base.id,
            createdAt: base.createdAt,
            updatedAt: DateUtils.nowIso(),
            situationText: base.situationText,
            sensations: base.sensations,
            automaticThoughts: base.automaticThoughts,
            emotions: base.emotions,
            thinkingStyles: base.thinkingStyles,
            adaptiveResponses: base.adaptiveResponses,
            outcomesByThought: base.outcomesByThought,
            beliefAfterMainThought: base.beliefAfterMainThought,
            notes: base.notes
        )
        draft = updated
        do {
            try await repository.saveDraft(updated)
        } catch {
            print("Persist draft failed", error)
        }
    }

    func loadDraft() async {
        do {
            if let stored = try await repository.fetchDraft() {
                draft = stored
            }
        } catch {
            print("Load draft failed", error)
        }
    }

    func clearDraft() async {
        do {
            try await repository.deleteDraft()
        } catch {
            print("Delete draft failed", error)
        }
        resetDraft()
    }
}
