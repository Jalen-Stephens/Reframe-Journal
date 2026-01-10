import XCTest
import SwiftData
@testable import ReframeJournal

final class AppStateTests: XCTestCase {
    
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    
    @MainActor

    
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
    func testAppStateInitialization() {
        let appState = AppState(modelContext: modelContext)
        
        XCTAssertNotNil(appState.repository)
        XCTAssertNotNil(appState.wizard)
        XCTAssertNotNil(appState.thoughtUsage)
    }
    
    @MainActor
    func testAppStateRepositoryIsThoughtRecordRepository() {
        let appState = AppState(modelContext: modelContext)
        
        // Repository should be initialized (it's declared as ThoughtRecordRepository, so this is always true)
        // But we can verify it's not nil
        XCTAssertNotNil(appState.repository)
    }
    
    @MainActor
    func testAppStateWizardIsWizardViewModel() {
        let appState = AppState(modelContext: modelContext)
        
        // Wizard should be initialized
        XCTAssertNotNil(appState.wizard)
    }
}
