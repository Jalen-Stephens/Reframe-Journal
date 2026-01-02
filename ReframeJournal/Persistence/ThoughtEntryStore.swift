import Foundation

@MainActor
final class ThoughtEntryStore {
    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
    }

    func fetchRecord(id: String) async throws -> ThoughtRecord? {
        try await repository.fetch(id: id)
    }

    func fetch(id: String) async throws -> ThoughtEntry? {
        guard let record = try await repository.fetch(id: id) else {
            return nil
        }
        return ThoughtEntry(record: record)
    }

    @discardableResult
    func upsert(_ entry: ThoughtEntry, baseRecord: ThoughtRecord? = nil) async throws -> ThoughtRecord {
        let resolvedRecord: ThoughtRecord?
        if let baseRecord {
            resolvedRecord = baseRecord
        } else {
            resolvedRecord = try await repository.fetch(id: entry.recordId)
        }
        let updated = entry.applying(to: resolvedRecord)
        try await repository.upsert(updated)
        return updated
    }

    func delete(id: String) async throws {
        try await repository.delete(id: id)
    }
}
