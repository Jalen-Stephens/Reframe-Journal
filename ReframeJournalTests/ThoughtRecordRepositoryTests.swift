import XCTest
import SwiftData
@testable import ReframeJournal

@MainActor
final class ThoughtRecordRepositoryTests: XCTestCase {
    
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
    
    func testRepositoryErrorDescriptions() {
        let entryNotFound = ThoughtRecordRepository.RepositoryError.entryNotFound
        XCTAssertNotNil(entryNotFound.errorDescription)
        XCTAssertTrue(entryNotFound.errorDescription?.contains("not found") ?? false)
        
        let saveFailed = ThoughtRecordRepository.RepositoryError.saveFailed(NSError(domain: "test", code: 1))
        XCTAssertNotNil(saveFailed.errorDescription)
    }
    
    func testFetchRecent() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        for i in 0..<5 {
            let entry = JournalEntry()
            entry.isDraft = false
            entry.createdAt = Date(timeIntervalSince1970: Double(i))
            modelContext.insert(entry)
        }
        try modelContext.save()
        
        let records = try await repository.fetchRecent(limit: 3)
        XCTAssertEqual(records.count, 3)
    }
    
    func testFetchAll() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.isDraft = false
        modelContext.insert(entry)
        try modelContext.save()
        
        let records = try await repository.fetchAll()
        XCTAssertEqual(records.count, 1)
    }
    
    func testFetchById() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try modelContext.save()
        
        let record = try await repository.fetch(id: id)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.id, id)
    }
    
    func testFetchByIdNotFound() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let record = try await repository.fetch(id: "nonexistent")
        XCTAssertNil(record)
    }
    
    func testFetchEntry() throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try modelContext.save()
        
        let fetched = try repository.fetchEntry(id: id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.recordId, id)
    }
    
    func testUpsert() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
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
        
        try await repository.upsert(record)
        
        let fetched = try await repository.fetch(id: "test_id")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.situationText, "Situation")
    }
    
    func testDelete() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try modelContext.save()
        
        try await repository.delete(id: id)
        
        let fetched = try await repository.fetch(id: id)
        XCTAssertNil(fetched)
    }
    
    func testFetchDraft() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.isDraft = true
        modelContext.insert(entry)
        try modelContext.save()
        
        let draft = try await repository.fetchDraft()
        XCTAssertNotNil(draft)
        XCTAssertTrue(draft?.completionStatus == .draft)
    }
    
    func testSaveDraft() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let record = ThoughtRecord(
            id: "draft_id",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Draft",
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
        
        try await repository.saveDraft(record)
        
        let draft = try await repository.fetchDraft()
        XCTAssertNotNil(draft)
        XCTAssertEqual(draft?.situationText, "Draft")
    }
    
    func testDeleteDraft() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        entry.isDraft = true
        modelContext.insert(entry)
        try modelContext.save()
        
        try await repository.deleteDraft()
        
        let draft = try await repository.fetchDraft()
        XCTAssertNil(draft)
    }
    
    func testUpsertAIReframe() async throws {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try modelContext.save()
        
        let aiReframe = AIReframeResult(
            validation: "Valid",
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "Balanced",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: "Summary",
            rawResponse: nil
        )
        
        try await repository.upsertAIReframe(
            entryId: id,
            result: aiReframe,
            model: "gpt-4",
            promptVersion: "v3",
            depth: .deep
        )
        
        let fetched = try repository.fetchEntry(id: id)
        XCTAssertNotNil(fetched?.aiReframe)
        XCTAssertEqual(fetched?.aiReframeModel, "gpt-4")
        XCTAssertEqual(fetched?.aiReframePromptVersion, "v3")
        XCTAssertEqual(fetched?.aiReframeDepth, .deep)
    }
    
    func testUpsertAIReframeNotFound() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        let aiReframe = AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "Test",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: nil,
            rawResponse: nil
        )
        
        do {
            try await repository.upsertAIReframe(entryId: "nonexistent", result: aiReframe)
            XCTFail("Should have thrown error")
        } catch {
            if case ThoughtRecordRepository.RepositoryError.entryNotFound = error {
                // Expected
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }
    
    func testFlushPendingWrites() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        // Should not throw
        await repository.flushPendingWrites()
    }
}
