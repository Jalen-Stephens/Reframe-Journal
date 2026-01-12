// File: Persistence/JournalEntryStore.swift
// SwiftData-based store for journal entries
// Replaces the JSON file-based ThoughtRecordStore

import Foundation
import SwiftData

// MARK: - JournalEntryStore

/// A store that manages JournalEntry persistence using SwiftData.
/// This replaces the old ThoughtRecordStore which used JSON files.
@MainActor
final class JournalEntryStore: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Operations
    
    /// Fetches all non-draft entries sorted by creation date (newest first)
    func fetchAll() throws -> [JournalEntry] {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { !$0.isDraft },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetches recent non-draft entries with optional limit
    func fetchRecent(limit: Int = 20) throws -> [JournalEntry] {
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { !$0.isDraft },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetches a specific entry by its record ID
    func fetch(id: String) throws -> JournalEntry? {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { entry in
                entry.recordId == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    /// Fetches the current draft entry (if any)
    func fetchDraft() throws -> JournalEntry? {
        let descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.isDraft }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Write Operations
    
    /// Inserts or updates an entry
    func upsert(_ entry: JournalEntry) throws {
        // Check if entry already exists in context
        if let existing = try fetch(id: entry.recordId) {
            // Update existing entry
            existing.title = entry.title
            existing.updatedAt = Date()
            existing.situationText = entry.situationText
            existing.sensations = entry.sensations
            existing.automaticThoughts = entry.automaticThoughts
            existing.emotions = entry.emotions
            existing.thinkingStyles = entry.thinkingStyles
            existing.adaptiveResponses = entry.adaptiveResponses
            existing.outcomesByThought = entry.outcomesByThought
            existing.beliefAfterMainThought = entry.beliefAfterMainThought
            existing.notes = entry.notes
            existing.aiReframe = entry.aiReframe
            existing.aiReframeCreatedAt = entry.aiReframeCreatedAt
            existing.aiReframeModel = entry.aiReframeModel
            existing.aiReframePromptVersion = entry.aiReframePromptVersion
            existing.aiReframeDepth = entry.aiReframeDepth
            existing.isDraft = entry.isDraft
        } else {
            // Insert new entry
            modelContext.insert(entry)
        }
        
        try modelContext.save()
    }
    
    /// Creates or updates an entry from a ThoughtRecord (for compatibility)
    func upsert(_ record: ThoughtRecord) throws {
        if let existing = try fetch(id: record.id) {
            existing.update(from: record)
            existing.isDraft = false
        } else {
            let entry = JournalEntry(from: record)
            entry.isDraft = false
            modelContext.insert(entry)
        }
        
        try modelContext.save()
    }
    
    /// Creates or updates an entry from an UrgeRecord
    func upsert(_ record: UrgeRecord) throws {
        if let existing = try fetch(id: record.id) {
            existing.urgeRecord = record
            existing.updatedAt = Date()
            existing.title = record.title
            existing.situationText = record.situationText
            existing.sensations = record.sensations
            existing.emotions = record.emotions
            existing.isDraft = false
        } else {
            let entry = JournalEntry(from: record)
            entry.isDraft = false
            modelContext.insert(entry)
        }
        
        try modelContext.save()
    }
    
    /// Deletes an entry by ID
    func delete(id: String) throws {
        if let entry = try fetch(id: id) {
            modelContext.delete(entry)
            try modelContext.save()
        }
    }
    
    /// Saves the current draft
    func saveDraft(_ entry: JournalEntry) throws {
        // Delete any existing draft first
        try deleteDraft()
        
        entry.isDraft = true
        modelContext.insert(entry)
        try modelContext.save()
    }
    
    /// Saves a ThoughtRecord as draft (for compatibility)
    func saveDraft(_ record: ThoughtRecord) throws {
        try deleteDraft()
        
        let entry = JournalEntry(from: record)
        entry.isDraft = true
        modelContext.insert(entry)
        try modelContext.save()
    }
    
    /// Deletes the current draft (if any)
    func deleteDraft() throws {
        if let draft = try fetchDraft() {
            modelContext.delete(draft)
            try modelContext.save()
        }
    }
    
    /// Saves any pending changes
    func save() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}

// MARK: - ThoughtRecord Compatibility Extensions

extension JournalEntryStore {
    /// Fetches all entries as ThoughtRecords (for compatibility with existing views)
    func fetchAllAsRecords() throws -> [ThoughtRecord] {
        try fetchAll().map { $0.toThoughtRecord() }
    }
    
    /// Fetches recent entries as ThoughtRecords
    func fetchRecentAsRecords(limit: Int = 20) throws -> [ThoughtRecord] {
        try fetchRecent(limit: limit).map { $0.toThoughtRecord() }
    }
    
    /// Fetches a specific entry as ThoughtRecord
    func fetchAsRecord(id: String) throws -> ThoughtRecord? {
        try fetch(id: id)?.toThoughtRecord()
    }
    
    /// Fetches the draft as ThoughtRecord
    func fetchDraftAsRecord() throws -> ThoughtRecord? {
        try fetchDraft()?.toThoughtRecord()
    }
}
