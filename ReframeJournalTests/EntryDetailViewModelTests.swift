import XCTest
import SwiftData
@testable import ReframeJournal

@MainActor
final class EntryDetailViewModelTests: XCTestCase {
    
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
        let viewModel = EntryDetailViewModel(repository: repository)
        
        XCTAssertNil(viewModel.record)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.hasLoaded)
    }
    
    func testLoad() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = EntryDetailViewModel(repository: repository)
        
        let entry = JournalEntry()
        entry.situationText = "Test situation"
        let id = entry.recordId
        modelContext.insert(entry)
        try! modelContext.save()
        
        await viewModel.load(id: id)
        
        XCTAssertNotNil(viewModel.record)
        XCTAssertEqual(viewModel.record?.situationText, "Test situation")
        XCTAssertTrue(viewModel.hasLoaded)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadNotFound() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = EntryDetailViewModel(repository: repository)
        
        await viewModel.load(id: "nonexistent")
        
        XCTAssertNil(viewModel.record)
        XCTAssertTrue(viewModel.hasLoaded)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testLoadIfNeeded() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = EntryDetailViewModel(repository: repository)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try! modelContext.save()
        
        await viewModel.loadIfNeeded(id: id)
        
        XCTAssertNotNil(viewModel.record)
        XCTAssertTrue(viewModel.hasLoaded)
    }
    
    func testLoadIfNeededSkipsIfAlreadyLoaded() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = EntryDetailViewModel(repository: repository)
        
        let entry = JournalEntry()
        let id = entry.recordId
        modelContext.insert(entry)
        try! modelContext.save()
        
        await viewModel.loadIfNeeded(id: id)
        let firstLoad = viewModel.record
        
        // Load again with same ID
        await viewModel.loadIfNeeded(id: id)
        
        // Should be the same record (not reloaded)
        XCTAssertEqual(viewModel.record?.id, firstLoad?.id)
    }
    
    func testLoadIfNeededReloadsIfDifferentId() async {
        let repository = ThoughtRecordRepository(modelContext: modelContext)
        let viewModel = EntryDetailViewModel(repository: repository)
        
        let entry1 = JournalEntry()
        entry1.situationText = "First"
        let id1 = entry1.recordId
        modelContext.insert(entry1)
        
        let entry2 = JournalEntry()
        entry2.situationText = "Second"
        let id2 = entry2.recordId
        modelContext.insert(entry2)
        
        try! modelContext.save()
        
        await viewModel.loadIfNeeded(id: id1)
        XCTAssertEqual(viewModel.record?.situationText, "First")
        
        await viewModel.loadIfNeeded(id: id2)
        XCTAssertEqual(viewModel.record?.situationText, "Second")
    }
}
