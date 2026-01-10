import XCTest
import SwiftData
@testable import ReframeJournal

@MainActor
final class AppStateTests: XCTestCase {
    
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
    
    func testAppStateInitialization() {
        let appState = AppState(modelContext: modelContext)
        
        XCTAssertNotNil(appState.repository)
        XCTAssertNotNil(appState.wizard)
        XCTAssertNotNil(appState.thoughtUsage)
    }
    
    func testAppStateRepositoryIsThoughtRecordRepository() {
        let appState = AppState(modelContext: modelContext)
        
        // Repository should be initialized
        XCTAssertTrue(appState.repository is ThoughtRecordRepository)
    }
    
    func testAppStateWizardIsWizardViewModel() {
        let appState = AppState(modelContext: modelContext)
        
        // Wizard should be initialized
        XCTAssertNotNil(appState.wizard)
    }
}
