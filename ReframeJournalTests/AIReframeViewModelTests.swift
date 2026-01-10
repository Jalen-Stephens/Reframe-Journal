import XCTest
import SwiftData
@testable import ReframeJournal

@MainActor
final class AIReframeViewModelTests: XCTestCase {
    
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
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let viewModel = AIReframeViewModel(
            entryId: "test_id",
            repository: repository,
            service: service,
            depth: .quick
        )
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertNil(viewModel.result)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadExistingWithRecord() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        
        let entry = JournalEntry()
        let id = entry.recordId
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
        entry.aiReframe = aiReframe
        entry.aiReframeDepth = .deep
        modelContext.insert(entry)
        try! modelContext.save()
        
        let viewModel = AIReframeViewModel(
            entryId: id,
            repository: repository,
            service: service,
            depth: .quick
        )
        
        await viewModel.loadExisting()
        
        XCTAssertNotNil(viewModel.result)
        XCTAssertEqual(viewModel.result?.balancedThought, "Balanced")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
    }
    
    func testLoadExistingWithDraft() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        
        let entry = JournalEntry()
        let id = entry.recordId
        entry.isDraft = true
        let aiReframe = AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "Draft reframe",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: nil,
            rawResponse: nil
        )
        entry.aiReframe = aiReframe
        modelContext.insert(entry)
        try! modelContext.save()
        
        let viewModel = AIReframeViewModel(
            entryId: id,
            repository: repository,
            service: service,
            depth: .quick
        )
        
        await viewModel.loadExisting()
        
        XCTAssertNotNil(viewModel.result)
        XCTAssertEqual(viewModel.result?.balancedThought, "Draft reframe")
    }
    
    func testLoadExistingNotFound() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let viewModel = AIReframeViewModel(
            entryId: "nonexistent",
            repository: repository,
            service: service,
            depth: .quick
        )
        
        await viewModel.loadExisting()
        
        XCTAssertNil(viewModel.result)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testUpdateDepth() {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let viewModel = AIReframeViewModel(
            entryId: "test",
            repository: repository,
            service: service,
            depth: .quick
        )
        
        XCTAssertEqual(viewModel.currentDepth(), .quick)
        
        viewModel.updateDepth(.deep)
        XCTAssertEqual(viewModel.currentDepth(), .deep)
    }
    
    func testCurrentDepth() {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        
        let viewModel1 = AIReframeViewModel(
            entryId: "test",
            repository: repository,
            service: service,
            depth: .quick
        )
        XCTAssertEqual(viewModel1.currentDepth(), .quick)
        
        let viewModel2 = AIReframeViewModel(
            entryId: "test",
            repository: repository,
            service: service,
            depth: .deep
        )
        XCTAssertEqual(viewModel2.currentDepth(), .deep)
    }
}
