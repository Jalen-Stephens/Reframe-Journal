import Foundation

@MainActor
final class ThoughtRecordRepository {
    private let store: ThoughtRecordStore

    enum RepositoryError: LocalizedError {
        case entryNotFound

        var errorDescription: String? {
            switch self {
            case .entryNotFound:
                return "Entry not found."
            }
        }
    }

    init(store: ThoughtRecordStore) {
        self.store = store
    }

    func fetchRecent(limit: Int = 20) async throws -> [ThoughtRecord] {
        try await store.fetchAll(limit: limit)
    }

    func fetchAll() async throws -> [ThoughtRecord] {
        try await store.fetchAll()
    }

    func fetch(id: String) async throws -> ThoughtRecord? {
        try await store.fetch(id: id)
    }

    func upsert(_ record: ThoughtRecord) async throws {
        try await store.upsert(record)
    }

    func delete(id: String) async throws {
        try await store.delete(id: id)
    }

    func fetchDraft() async throws -> ThoughtRecord? {
        try await store.fetchDraft()
    }

    func saveDraft(_ record: ThoughtRecord) async throws {
        try await store.saveDraft(record)
    }

    func deleteDraft() async throws {
        try await store.deleteDraft()
    }

    func upsertAIReframe(entryId: String, result: AIReframeResult, createdAt: Date = Date(), model: String? = nil, promptVersion: String? = nil) async throws {
        guard var record = try await store.fetch(id: entryId) else {
            throw RepositoryError.entryNotFound
        }
        record.aiReframe = result
        record.aiReframeCreatedAt = createdAt
        record.aiReframeModel = model
        record.aiReframePromptVersion = promptVersion
        record.updatedAt = DateUtils.nowIso()
        try await store.upsert(record)
    }

    func flushPendingWrites() async {
        await store.flushPendingWrites()
    }
}
