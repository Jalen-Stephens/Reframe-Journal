import XCTest
@testable import ReframeJournal

final class IdentifiersTests: XCTestCase {
    
    // MARK: - generateId Tests
    
    func testGenerateIdHasPrefix() {
        let id = Identifiers.generateId()
        XCTAssertTrue(id.hasPrefix("id_"))
    }
    
    func testGenerateIdIsUnique() {
        let ids = (0..<100).map { _ in Identifiers.generateId() }
        let uniqueIds = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIds.count, "All generated IDs should be unique")
    }
    
    func testGenerateIdContainsUUID() {
        let id = Identifiers.generateId()
        let uuidPart = String(id.dropFirst(3)) // Remove "id_" prefix
        
        // Should be a valid UUID format (36 characters with hyphens)
        XCTAssertEqual(uuidPart.count, 36)
        XCTAssertNotNil(UUID(uuidString: uuidPart))
    }
    
    func testGenerateIdLength() {
        let id = Identifiers.generateId()
        // "id_" (3) + UUID (36) = 39
        XCTAssertEqual(id.count, 39)
    }
    
    // MARK: - Notification.Name Tests
    
    func testThoughtEntrySavedNotificationName() {
        let name = Notification.Name.thoughtEntrySaved
        XCTAssertEqual(name.rawValue, "thoughtEntrySaved")
    }
}

// MARK: - NotesDraftStore Tests

final class NotesDraftStoreTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        NotesDraftStore.clear()
    }
    
    override func tearDown() {
        NotesDraftStore.clear()
        super.tearDown()
    }
    
    func testSaveAndLoadDraft() {
        let entryId = "test_entry_123"
        let section = ThoughtEntryViewModel.Section.emotions
        
        NotesDraftStore.save(entryId: entryId, section: section)
        
        let loaded = NotesDraftStore.load()
        
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.entryId, entryId)
        XCTAssertEqual(loaded?.section, section)
    }
    
    func testLoadWithNoDraft() {
        NotesDraftStore.clear()
        
        let loaded = NotesDraftStore.load()
        
        XCTAssertNil(loaded)
    }
    
    func testClearDraft() {
        NotesDraftStore.save(entryId: "test", section: .situation)
        
        NotesDraftStore.clear()
        
        let loaded = NotesDraftStore.load()
        XCTAssertNil(loaded)
    }
    
    func testSaveOverwritesPrevious() {
        NotesDraftStore.save(entryId: "first", section: .situation)
        NotesDraftStore.save(entryId: "second", section: .emotions)
        
        let loaded = NotesDraftStore.load()
        
        XCTAssertEqual(loaded?.entryId, "second")
        XCTAssertEqual(loaded?.section, .emotions)
    }
    
    func testAllSections() {
        for section in ThoughtEntryViewModel.Section.allCases {
            NotesDraftStore.save(entryId: "test", section: section)
            let loaded = NotesDraftStore.load()
            XCTAssertEqual(loaded?.section, section)
        }
    }
    
    func testDraftEquality() {
        let draft1 = NotesDraftStore.Draft(entryId: "id1", section: .situation)
        let draft2 = NotesDraftStore.Draft(entryId: "id1", section: .situation)
        let draft3 = NotesDraftStore.Draft(entryId: "id2", section: .situation)
        let draft4 = NotesDraftStore.Draft(entryId: "id1", section: .emotions)
        
        XCTAssertEqual(draft1, draft2)
        XCTAssertNotEqual(draft1, draft3)
        XCTAssertNotEqual(draft1, draft4)
    }
}
