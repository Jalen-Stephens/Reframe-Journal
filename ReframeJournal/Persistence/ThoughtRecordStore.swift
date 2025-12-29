import Foundation

actor ThoughtRecordStore {
    private let baseURL: URL
    private let recordsURL: URL
    private let draftURL: URL

    init(baseURL: URL? = nil) {
        let fileManager = FileManager.default
        let root = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = root.appendingPathComponent("ReframeJournal", isDirectory: true)
        self.baseURL = directory
        self.recordsURL = directory.appendingPathComponent("thought_records.json")
        self.draftURL = directory.appendingPathComponent("wizard_draft.json")
    }

    private func ensureDirectory() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    private func loadRecords() throws -> [ThoughtRecord] {
        try ensureDirectory()
        guard FileManager.default.fileExists(atPath: recordsURL.path) else {
            return []
        }
        let data = try Data(contentsOf: recordsURL)
        let decoder = JSONDecoder()
        return try decoder.decode([ThoughtRecord].self, from: data)
    }

    private func saveRecords(_ records: [ThoughtRecord]) throws {
        try ensureDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records)
        try data.write(to: recordsURL, options: [.atomic])
    }

    func fetchAll(limit: Int? = nil) async throws -> [ThoughtRecord] {
        let records = try loadRecords()
        let sorted = records.sorted { lhs, rhs in
            let left = DateUtils.parseIso(lhs.createdAt) ?? .distantPast
            let right = DateUtils.parseIso(rhs.createdAt) ?? .distantPast
            return left > right
        }
        if let limit {
            return Array(sorted.prefix(limit))
        }
        return sorted
    }

    func fetch(id: String) async throws -> ThoughtRecord? {
        let records = try loadRecords()
        return records.first { $0.id == id }
    }

    func upsert(_ record: ThoughtRecord) async throws {
        var records = try loadRecords()
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index] = record
        } else {
            records.append(record)
        }
        try saveRecords(records)
    }

    func delete(id: String) async throws {
        var records = try loadRecords()
        records.removeAll { $0.id == id }
        try saveRecords(records)
    }

    func fetchDraft() async throws -> ThoughtRecord? {
        try ensureDirectory()
        guard FileManager.default.fileExists(atPath: draftURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: draftURL)
        return try JSONDecoder().decode(ThoughtRecord.self, from: data)
    }

    func saveDraft(_ record: ThoughtRecord) async throws {
        try ensureDirectory()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(record)
        try data.write(to: draftURL, options: [.atomic])
    }

    func deleteDraft() async throws {
        try ensureDirectory()
        if FileManager.default.fileExists(atPath: draftURL.path) {
            try FileManager.default.removeItem(at: draftURL)
        }
    }
}
