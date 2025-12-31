import Foundation

final class ThoughtRecordStore: ObservableObject {
    @Published private(set) var entries: [ThoughtRecord] = []

    private let baseURL: URL
    private let recordsURL: URL
    private let draftURL: URL

    private var didLoad = false
    private var loadTask: Task<[ThoughtRecord], Error>?
    private var didLoadDraft = false
    private var draftCache: ThoughtRecord?
    private var pendingSave: Task<Void, Never>?
    private var flushTask: Task<Void, Never>?

    init(baseURL: URL? = nil) {
        let fileManager = FileManager.default
        let root = baseURL ?? fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = root.appendingPathComponent("ReframeJournal", isDirectory: true)
        self.baseURL = directory
        self.recordsURL = directory.appendingPathComponent("thought_records.json")
        self.draftURL = directory.appendingPathComponent("wizard_draft.json")
    }

    func loadOnce() async throws {
        guard !didLoad else { return }
        if let loadTask {
            let records = try await loadTask.value
            entries = sortRecords(records)
            didLoad = true
            return
        }
        let task = Task { try await readRecordsFromDisk() }
        loadTask = task
        do {
            let records = try await task.value
            entries = sortRecords(records)
            didLoad = true
            loadTask = nil
        } catch {
            loadTask = nil
            throw error
        }
    }

    func fetchAll(limit: Int? = nil) async throws -> [ThoughtRecord] {
        try await loadOnce()
        if let limit {
            return Array(entries.prefix(limit))
        }
        return entries
    }

    func fetch(id: String) async throws -> ThoughtRecord? {
        try await loadOnce()
        return entries.first { $0.id == id }
    }

    func upsert(_ record: ThoughtRecord) async throws {
        try await loadOnce()
        if let index = entries.firstIndex(where: { $0.id == record.id }) {
            entries[index] = record
        } else {
            entries.append(record)
        }
        entries = sortRecords(entries)
        scheduleSave(records: entries)
    }

    func delete(id: String) async throws {
        try await loadOnce()
        entries.removeAll { $0.id == id }
        scheduleSave(records: entries)
    }

    func fetchDraft() async throws -> ThoughtRecord? {
        try await loadDraftOnce()
        return draftCache
    }

    func saveDraft(_ record: ThoughtRecord) async throws {
        draftCache = record
        didLoadDraft = true
        try await writeDraftToDisk(record)
    }

    func deleteDraft() async throws {
        draftCache = nil
        didLoadDraft = true
        try ensureDirectory()
        if FileManager.default.fileExists(atPath: draftURL.path) {
            try FileManager.default.removeItem(at: draftURL)
        }
    }

    private func loadDraftOnce() async throws {
        guard !didLoadDraft else { return }
        didLoadDraft = true
        draftCache = try await readDraftFromDisk()
    }

    private func ensureDirectory() throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: baseURL.path) {
            try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    private func readRecordsFromDisk() async throws -> [ThoughtRecord] {
        try await Task.detached(priority: .utility) { [baseURL, recordsURL] in
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: baseURL.path) {
                try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            }
            guard fileManager.fileExists(atPath: recordsURL.path) else {
                return []
            }
#if DEBUG
            print("DISK READ thought_records.json")
#endif
            let data = try Data(contentsOf: recordsURL)
#if DEBUG
            print("DECODE thought_records.json")
#endif
            let decoder = JSONDecoder()
            return try decoder.decode([ThoughtRecord].self, from: data)
        }.value
    }

    private func readDraftFromDisk() async throws -> ThoughtRecord? {
        try await Task.detached(priority: .utility) { [baseURL, draftURL] in
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: baseURL.path) {
                try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            }
            guard fileManager.fileExists(atPath: draftURL.path) else {
                return nil
            }
#if DEBUG
            print("DISK READ wizard_draft.json")
#endif
            let data = try Data(contentsOf: draftURL)
#if DEBUG
            print("DECODE wizard_draft.json")
#endif
            return try JSONDecoder().decode(ThoughtRecord.self, from: data)
        }.value
    }

    private func scheduleSave(records: [ThoughtRecord]) {
        pendingSave?.cancel()
        let snapshot = records
        let baseURL = baseURL
        let recordsURL = recordsURL
#if DEBUG
        print("DEBOUNCE WRITE scheduled")
#endif
        pendingSave = Task.detached(priority: .utility) { [baseURL, recordsURL, snapshot, weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: baseURL.path) {
                    try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
                }
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
#if DEBUG
                print("ENCODE thought_records.json")
#endif
                let data = try encoder.encode(snapshot)
                try data.write(to: recordsURL, options: [.atomic])
            } catch {
#if DEBUG
                if !Task.isCancelled {
                    print("Persist records failed", error)
                }
#endif
            }
            await MainActor.run {
                self?.pendingSave = nil
            }
        }
    }

    func flushPendingWrites() async {
        guard pendingSave != nil else { return }
        if flushTask != nil { return }
        pendingSave?.cancel()
        pendingSave = nil
        let snapshot = entries
        let baseURL = baseURL
        let recordsURL = recordsURL
        let task = Task.detached(priority: .utility) {
            do {
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: baseURL.path) {
                    try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
                }
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
#if DEBUG
                print("FLUSH WRITE executed")
#endif
                let data = try encoder.encode(snapshot)
                try data.write(to: recordsURL, options: [.atomic])
            } catch {
#if DEBUG
                print("Flush records failed", error)
#endif
            }
        }
        flushTask = task
        await task.value
        flushTask = nil
    }

    private func writeDraftToDisk(_ record: ThoughtRecord) async throws {
        try await Task.detached(priority: .utility) { [baseURL, draftURL] in
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: baseURL.path) {
                try fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
            }
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
#if DEBUG
            print("ENCODE wizard_draft.json")
#endif
            let data = try encoder.encode(record)
            try data.write(to: draftURL, options: [.atomic])
        }.value
    }

    private func sortRecords(_ records: [ThoughtRecord]) -> [ThoughtRecord] {
        records.sorted { lhs, rhs in
            let left = DateUtils.parseIso(lhs.createdAt) ?? .distantPast
            let right = DateUtils.parseIso(rhs.createdAt) ?? .distantPast
            return left > right
        }
    }
}
