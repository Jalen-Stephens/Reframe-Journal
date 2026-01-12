// File: Services/ThoughtRecordRepository.swift
// Repository layer for journal entry persistence
// Now uses SwiftData via JournalEntryStore

import Foundation
import SwiftData

@MainActor
final class ThoughtRecordRepository: ObservableObject {
    private let store: JournalEntryStore
    
    enum RepositoryError: LocalizedError {
        case entryNotFound
        case saveFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .entryNotFound:
                return "Entry not found."
            case .saveFailed(let error):
                return "Failed to save: \(error.localizedDescription)"
            }
        }
    }
    
    init(modelContext: ModelContext) {
        self.store = JournalEntryStore(modelContext: modelContext)
    }
    
    // MARK: - Fetch Operations
    
    func fetchRecent(limit: Int = 20) async throws -> [ThoughtRecord] {
        try store.fetchRecentAsRecords(limit: limit)
    }
    
    func fetchAll() async throws -> [ThoughtRecord] {
        try store.fetchAllAsRecords()
    }
    
    func fetch(id: String) async throws -> ThoughtRecord? {
        try store.fetchAsRecord(id: id)
    }
    
    /// Fetches a JournalEntry directly (for use with SwiftData @Query)
    func fetchEntry(id: String) throws -> JournalEntry? {
        try store.fetch(id: id)
    }
    
    // MARK: - Write Operations
    
    func upsert(_ record: ThoughtRecord) async throws {
        do {
            try store.upsert(record)
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }
    
    func delete(id: String) async throws {
        try store.delete(id: id)
    }
    
    // MARK: - Draft Operations
    
    func fetchDraft() async throws -> ThoughtRecord? {
        try store.fetchDraftAsRecord()
    }
    
    func saveDraft(_ record: ThoughtRecord) async throws {
        try store.saveDraft(record)
    }
    
    func deleteDraft() async throws {
        try store.deleteDraft()
    }
    
    // MARK: - Urge Entry Operations
    
    func upsertUrge(_ record: UrgeRecord) async throws {
        do {
            try store.upsert(record)
        } catch {
            throw RepositoryError.saveFailed(error)
        }
    }
    
    func fetchUrge(id: String) async throws -> UrgeRecord? {
        guard let entry = try store.fetch(id: id), entry.entryType == .urge else {
            return nil
        }
        return entry.urgeRecord
    }
    
    // MARK: - AI Reframe Operations
    
    func upsertAIReframe(
        entryId: String,
        result: AIReframeResult,
        createdAt: Date = Date(),
        model: String? = nil,
        promptVersion: String? = nil,
        depth: AIReframeDepth? = nil
    ) async throws {
        guard let entry = try store.fetch(id: entryId) else {
            throw RepositoryError.entryNotFound
        }
        
        entry.aiReframe = result
        entry.aiReframeCreatedAt = createdAt
        entry.aiReframeModel = model
        entry.aiReframePromptVersion = promptVersion
        entry.aiReframeDepth = depth
        entry.updatedAt = Date()
        
        try store.save()
    }
    
    // MARK: - Compatibility
    
    /// No longer needed with SwiftData - writes are immediate
    func flushPendingWrites() async {
        // SwiftData saves are synchronous, no flushing needed
        try? store.save()
    }
}
