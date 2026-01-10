import XCTest
import SwiftData
@testable import ReframeJournal

@MainActor
final class WizardViewModelTests: XCTestCase {
    
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
    
    func testInitialState() {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        XCTAssertFalse(viewModel.isEditing)
        XCTAssertFalse(viewModel.hasLoadedDraft)
        XCTAssertNotNil(viewModel.draft)
        XCTAssertTrue(viewModel.draft.recordId.hasPrefix("id_"))
    }
    
    func testResetDraft() {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        let originalId = viewModel.draft.id
        viewModel.draft.situationText = "Modified"
        viewModel.isEditing = true
        
        viewModel.resetDraft()
        
        XCTAssertNotEqual(viewModel.draft.id, originalId)
        XCTAssertEqual(viewModel.draft.situationText, "")
        XCTAssertFalse(viewModel.isEditing)
    }
    
    func testSetDraft() {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        let record = ThoughtRecord(
            id: "test_id",
            title: "Test",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test situation",
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
        
        viewModel.setDraft(record, isEditing: true)
        
        XCTAssertEqual(viewModel.draft.id, "test_id")
        XCTAssertEqual(viewModel.draft.situationText, "Test situation")
        XCTAssertTrue(viewModel.isEditing)
    }
    
    func testPersistDraft() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        let record = ThoughtRecord(
            id: "draft_id",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Draft situation",
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
        
        viewModel.draft = record
        await viewModel.persistDraft()
        
        // Wait a bit for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify draft was saved
        let savedDraft = try? await repository.fetchDraft()
        XCTAssertNotNil(savedDraft)
        XCTAssertEqual(savedDraft?.situationText, "Draft situation")
    }
    
    func testPersistDraftWithProvidedRecord() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        let providedRecord = ThoughtRecord(
            id: "provided_id",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Provided situation",
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
        
        await viewModel.persistDraft(providedRecord)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let savedDraft = try? await repository.fetchDraft()
        XCTAssertNotNil(savedDraft)
        XCTAssertEqual(savedDraft?.id, "provided_id")
        XCTAssertEqual(viewModel.draft.id, "provided_id")
    }
    
    func testLoadDraft() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        
        // Create and save a draft first
        let draftRecord = ThoughtRecord(
            id: "saved_draft",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Saved draft",
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
        
        try? await repository.saveDraft(draftRecord)
        
        // Create viewModel - it should load the draft on init
        let viewModel = WizardViewModel(repository: repository)
        
        // Wait for async load
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // After load, draft should be updated
        XCTAssertTrue(viewModel.hasLoadedDraft)
    }
    
    func testClearDraft() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        // Save a draft
        let draftRecord = ThoughtRecord(
            id: "to_clear",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "To clear",
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
        
        viewModel.draft = draftRecord
        await viewModel.persistDraft()
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Clear draft
        await viewModel.clearDraft()
        
        // Verify draft is cleared
        let draft = try? await repository.fetchDraft()
        XCTAssertNil(draft)
        XCTAssertFalse(viewModel.isEditing)
    }
    
    func testLoadDraftIsIdempotent() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = WizardViewModel(repository: repository)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        let firstLoad = viewModel.hasLoadedDraft
        
        // Load multiple times
        await viewModel.loadDraft()
        await viewModel.loadDraft()
        await viewModel.loadDraft()
        
        // Should remain in same state
        XCTAssertEqual(viewModel.hasLoadedDraft, firstLoad)
    }
}
