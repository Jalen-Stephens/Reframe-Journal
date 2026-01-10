import XCTest
import SwiftData
@testable import ReframeJournal

final class JournalEntryStoreTests: XCTestCase {
    
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: JournalEntry.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    @MainActor
    func testFetchAllWithNoEntries() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        let entries = try store.fetchAll()
        XCTAssertTrue(entries.isEmpty)
    }
    
    @MainActor
    func testFetchAllExcludesDrafts() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let draft = JournalEntry()
        draft.isDraft = true
        modelContext.insert(draft)
        
        let entry = JournalEntry()
        entry.isDraft = false
        modelContext.insert(entry)
        
        try modelContext.save()
        
        let entries = try store.fetchAll()
        XCTAssertEqual(entries.count, 1)
        XCTAssertFalse(entries.first?.isDraft ?? true)
    }
    
    @MainActor
    func testFetchRecent() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        for i in 0..<5 {
            let entry = JournalEntry()
            entry.isDraft = false
            entry.createdAt = Date(timeIntervalSince1970: Double(i))
            modelContext.insert(entry)
        }
        
        try modelContext.save()
        
        let recent = try store.fetchRecent(limit: 3)
        XCTAssertEqual(recent.count, 3)
    }
    
    @MainActor
    func testFetchById() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try modelContext.save()
        
        let fetched = try store.fetch(id: id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.recordId, id)
    }
    
    @MainActor
    func testFetchByIdNotFound() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        let fetched = try store.fetch(id: "nonexistent")
        XCTAssertNil(fetched)
    }
    
    @MainActor
    func testFetchDraft() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let draft = JournalEntry()
        draft.isDraft = true
        modelContext.insert(draft)
        try modelContext.save()
        
        let fetched = try store.fetchDraft()
        XCTAssertNotNil(fetched)
        XCTAssertTrue(fetched?.isDraft ?? false)
    }
    
    @MainActor
    func testFetchDraftWhenNoneExists() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        let fetched = try store.fetchDraft()
        XCTAssertNil(fetched)
    }
    
    @MainActor
    func testUpsertNewEntry() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.situationText = "Test situation"
        entry.isDraft = false
        
        try store.upsert(entry)
        
        let fetched = try store.fetch(id: entry.recordId)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.situationText, "Test situation")
    }
    
    @MainActor
    func testUpsertUpdatesExisting() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.situationText = "Original"
        modelContext.insert(entry)
        try modelContext.save()
        
        entry.situationText = "Updated"
        try store.upsert(entry)
        
        let fetched = try store.fetch(id: entry.recordId)
        XCTAssertEqual(fetched?.situationText, "Updated")
    }
    
    @MainActor
    func testUpsertThoughtRecord() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let record = ThoughtRecord(
            id: "test_id",
            title: "Test",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Situation",
            sensations: [],
            automaticThoughts: [],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: nil,
            selectedValues: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        try store.upsert(record)
        
        let fetched = try store.fetch(id: "test_id")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.situationText, "Situation")
        XCTAssertFalse(fetched?.isDraft ?? true)
    }
    
    @MainActor
    func testDelete() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try modelContext.save()
        
        try store.delete(id: id)
        
        let fetched = try store.fetch(id: id)
        XCTAssertNil(fetched)
    }
    
    @MainActor
    func testSaveDraft() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.situationText = "Draft"
        
        try store.saveDraft(entry)
        
        let draft = try store.fetchDraft()
        XCTAssertNotNil(draft)
        XCTAssertTrue(draft?.isDraft ?? false)
        XCTAssertEqual(draft?.situationText, "Draft")
    }
    
    @MainActor
    func testSaveDraftReplacesExisting() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let draft1 = JournalEntry()
        draft1.situationText = "First"
        try store.saveDraft(draft1)
        
        let draft2 = JournalEntry()
        draft2.situationText = "Second"
        try store.saveDraft(draft2)
        
        let draft = try store.fetchDraft()
        XCTAssertEqual(draft?.situationText, "Second")
    }
    
    @MainActor
    func testDeleteDraft() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let draft = JournalEntry()
        try store.saveDraft(draft)
        
        try store.deleteDraft()
        
        let fetched = try store.fetchDraft()
        XCTAssertNil(fetched)
    }
    
    @MainActor
    func testFetchAllAsRecords() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.situationText = "Test"
        entry.isDraft = false
        modelContext.insert(entry)
        try modelContext.save()
        
        let records = try store.fetchAllAsRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.situationText, "Test")
    }
    
    @MainActor
    func testFetchRecentAsRecords() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        for i in 0..<3 {
            let entry = JournalEntry()
            entry.isDraft = false
            entry.createdAt = Date(timeIntervalSince1970: Double(i))
            modelContext.insert(entry)
        }
        try modelContext.save()
        
        let records = try store.fetchRecentAsRecords(limit: 2)
        XCTAssertEqual(records.count, 2)
    }
    
    @MainActor
    func testFetchAsRecord() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        entry.situationText = "Test"
        modelContext.insert(entry)
        try modelContext.save()
        
        let record = try store.fetchAsRecord(id: id)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.situationText, "Test")
    }
    
    @MainActor
    func testFetchDraftAsRecord() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let draft = JournalEntry()
        draft.situationText = "Draft"
        try store.saveDraft(draft)
        
        let record = try store.fetchDraftAsRecord()
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.situationText, "Draft")
    }
    
    @MainActor
    func testSave() throws {
        let store = JournalEntryStore(modelContext: modelContext)
        
        let entry = JournalEntry()
        modelContext.insert(entry)
        
        try store.save()
        
        let fetched = try store.fetch(id: entry.recordId)
        XCTAssertNotNil(fetched)
    }
}
