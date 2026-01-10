import XCTest
import SwiftData
@testable import ReframeJournal

final class ModelContainerConfigTests: XCTestCase {
    
    func testSchemaContainsRequiredModels() {
        let schema = ModelContainerConfig.schema
        
        XCTAssertTrue(schema.entities.contains { $0.name == "JournalEntry" })
        XCTAssertTrue(schema.entities.contains { $0.name == "ValuesProfileData" })
        XCTAssertTrue(schema.entities.contains { $0.name == "ValuesCategoryEntryData" })
    }
    
    func testMakeContainer() throws {
        let container = try ModelContainerConfig.makeContainer()
        
        XCTAssertNotNil(container)
        let config = container.configurations.first
        XCTAssertNotNil(config)
    }
    
    func testMakePreviewContainer() throws {
        let container = try ModelContainerConfig.makePreviewContainer()
        
        XCTAssertNotNil(container)
        let config = container.configurations.first
        XCTAssertNotNil(config)
        XCTAssertTrue(config?.isStoredInMemoryOnly ?? false)
    }
    
    @MainActor
    func testPreviewContainerHasSampleData() {
        let container = ModelContainer.preview
        
        XCTAssertNotNil(container)
        let context = container.mainContext
        
        let descriptor = FetchDescriptor<JournalEntry>()
        let entries = try? context.fetch(descriptor)
        XCTAssertGreaterThan(entries?.count ?? 0, 0)
    }
}
