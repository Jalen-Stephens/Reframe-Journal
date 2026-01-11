import XCTest
import SwiftData
@testable import ReframeJournal

final class ValuesProfileServiceTests: XCTestCase {
    
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    
    @MainActor
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: ValuesProfileData.self, configurations: config)
        modelContext = modelContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    @MainActor
    func testInitialState() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Service starts with empty profile
        XCTAssertEqual(service.profile.entries.count, 10) // All categories from empty profile
        XCTAssertFalse(service.isLoaded) // Initially false, will load async
        
        // Wait for async load
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // After load, should still have 10 entries
        XCTAssertTrue(service.isLoaded)
        XCTAssertEqual(service.profile.entries.count, 10)
    }
    
    @MainActor
    func testLoadCreatesNewProfile() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        await service.load()
        
        XCTAssertTrue(service.isLoaded)
        XCTAssertEqual(service.profile.entries.count, 10)
        
        // Verify profile was saved to context
        let descriptor = FetchDescriptor<ValuesProfileData>()
        let profiles = try? modelContext.fetch(descriptor)
        XCTAssertEqual(profiles?.count, 1)
    }
    
    @MainActor
    func testUpdateEntry() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        let entry = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "Support",
            whyItMatters: "Important",
            keywords: ["loyalty", "trust"],
            importance: 5
        )
        
        service.updateEntry(entry)
        
        // Wait a bit for async operations
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let retrievedEntry = service.entry(for: .friends)
        XCTAssertEqual(retrievedEntry.whatMatters, "Support")
        XCTAssertEqual(retrievedEntry.whyItMatters, "Important")
        XCTAssertEqual(retrievedEntry.keywords, ["loyalty", "trust"])
        XCTAssertEqual(retrievedEntry.importance, 5)
    }
    
    @MainActor
    func testUpdateEntryPersists() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        let entry = ValuesCategoryEntry(category: .friends, whatMatters: "Support")
        service.updateEntry(entry)
        
        // Wait for persistence
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Create new service instance to verify persistence
        let service2 = ValuesProfileService(modelContext: modelContext)
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service2.load()
        
        let retrievedEntry = service2.entry(for: .friends)
        XCTAssertEqual(retrievedEntry.whatMatters, "Support")
    }
    
    @MainActor
    func testEntryForCategory() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        let entry = service.entry(for: .romanticRelationships)
        XCTAssertEqual(entry.category, .romanticRelationships)
        XCTAssertFalse(entry.hasContent)
    }
    
    @MainActor
    func testUpdateProfile() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        var profile = ValuesProfile.empty()
        let entry = ValuesCategoryEntry(category: .friends, whatMatters: "Support")
        profile.updateEntry(entry)
        
        service.updateProfile(profile)
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        let retrievedEntry = service.entry(for: .friends)
        XCTAssertEqual(retrievedEntry.whatMatters, "Support")
    }
    
    @MainActor
    func testCreateSnippet() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        // Add content to profile
        let entry = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "Support matters",
            howToShowUp: "Be there"
        )
        service.updateEntry(entry)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Create snippet
        let selection = SelectedValues(categories: [.friends], howToShowUp: "Be present")
        let snippet = service.createSnippet(for: selection)
        
        XCTAssertTrue(snippet.hasContent)
        XCTAssertEqual(snippet.categories.count, 1)
        XCTAssertEqual(snippet.howToShowUp, "Be present")
    }
    
    @MainActor
    func testClear() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        // Add content
        let entry = ValuesCategoryEntry(category: .friends, whatMatters: "Support")
        service.updateEntry(entry)
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // Clear
        await service.clear()
        
        // Verify cleared
        let clearedEntry = service.entry(for: .friends)
        XCTAssertFalse(clearedEntry.hasContent)
    }
    
    @MainActor
    func testUpdateModelContext() async {
        let service1 = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service1.load()
        
        // Create new context
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let newContainer = try! ModelContainer(for: ValuesProfileData.self, configurations: config)
        let newContext = newContainer.mainContext
        
        // Update context (should trigger reload)
        service1.updateModelContext(newContext)
        
        // Wait for reload
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Should have loaded with new context
        XCTAssertTrue(service1.isLoaded)
    }
    
    @MainActor
    func testUpdateModelContextSameContext() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        await service.load()
        
        let wasLoaded = service.isLoaded
        
        // Update with same context (should not reload)
        service.updateModelContext(modelContext)
        
        // Wait a bit
        try? await Task.sleep(nanoseconds: 50_000_000)
        
        // Should still be loaded (no change)
        XCTAssertEqual(service.isLoaded, wasLoaded)
    }
    
    @MainActor
    func testLoadIsIdempotent() async {
        let service = ValuesProfileService(modelContext: modelContext)
        
        // Wait for initial load
        try? await Task.sleep(nanoseconds: 200_000_000)
        
        // Load multiple times
        await service.load()
        await service.load()
        await service.load()
        
        // Should only create one profile
        let descriptor = FetchDescriptor<ValuesProfileData>()
        let profiles = try? modelContext.fetch(descriptor)
        XCTAssertEqual(profiles?.count, 1)
    }
}
