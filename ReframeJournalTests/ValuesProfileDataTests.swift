import XCTest
import SwiftData
@testable import ReframeJournal

final class ValuesProfileDataTests: XCTestCase {
    
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
    func testValuesProfileDataCreation() {
        let profileData = ValuesProfileData(
            id: "test_id",
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 1)
        )
        
        XCTAssertEqual(profileData.id, "test_id")
        XCTAssertTrue(profileData.entries.isEmpty)
        XCTAssertNotNil(profileData.createdAt)
        XCTAssertNotNil(profileData.updatedAt)
    }
    
    @MainActor
    func testValuesProfileDataDefaultInit() {
        let profileData = ValuesProfileData()
        
        XCTAssertTrue(profileData.id.hasPrefix("id_"))
        XCTAssertTrue(profileData.entries.isEmpty)
        XCTAssertNotNil(profileData.createdAt)
        XCTAssertNotNil(profileData.updatedAt)
    }
    
    @MainActor
    func testEntryForCategoryCreatesNew() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entry = profileData.entry(for: .friends)
        
        XCTAssertEqual(entry.category, .friends)
        XCTAssertEqual(entry.categoryRaw, "friends")
        XCTAssertTrue(entry.whatMatters.isEmpty)
        XCTAssertTrue(profileData.entries.contains(entry))
    }
    
    @MainActor
    func testEntryForCategoryReturnsExisting() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entry1 = profileData.entry(for: .friends)
        entry1.whatMatters = "Support"
        
        let entry2 = profileData.entry(for: .friends)
        
        XCTAssertEqual(entry1.id, entry2.id)
        XCTAssertEqual(entry2.whatMatters, "Support")
        XCTAssertEqual(profileData.entries.count, 1)
    }
    
    @MainActor
    func testUpdateEntryAddsNew() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entry = ValuesCategoryEntryData(
            category: .friends,
            whatMatters: "Support",
            keywords: ["loyalty"]
        )
        
        profileData.updateEntry(entry)
        
        XCTAssertEqual(profileData.entries.count, 1)
        let retrieved = profileData.entries.first!
        XCTAssertEqual(retrieved.category, .friends)
        XCTAssertEqual(retrieved.whatMatters, "Support")
    }
    
    @MainActor
    func testUpdateEntryUpdatesExisting() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entry1 = profileData.entry(for: .friends)
        entry1.whatMatters = "Original"
        entry1.importance = 3
        
        var updatedEntry = ValuesCategoryEntryData(
            id: entry1.id,
            category: .friends,
            whatMatters: "Updated",
            keywords: ["loyalty"]
        )
        updatedEntry.importance = 5
        
        profileData.updateEntry(updatedEntry)
        
        XCTAssertEqual(profileData.entries.count, 1)
        let retrieved = profileData.entries.first!
        XCTAssertEqual(retrieved.id, entry1.id)
        XCTAssertEqual(retrieved.whatMatters, "Updated")
        XCTAssertEqual(retrieved.importance, 5)
        XCTAssertEqual(retrieved.keywords, ["loyalty"])
    }
    
    @MainActor
    func testToValuesProfile() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entry1 = profileData.entry(for: .friends)
        entry1.whatMatters = "Support"
        entry1.keywords = ["loyalty", "trust"]
        
        let entry2 = profileData.entry(for: .romanticRelationships)
        entry2.whatMatters = "Love"
        
        let profile = profileData.toValuesProfile()
        
        XCTAssertEqual(profile.id, profileData.id)
        XCTAssertEqual(profile.entries.count, 2)
        XCTAssertEqual(profile.entry(for: .friends).whatMatters, "Support")
        XCTAssertEqual(profile.entry(for: .friends).keywords, ["loyalty", "trust"])
        XCTAssertEqual(profile.entry(for: .romanticRelationships).whatMatters, "Love")
    }
    
    @MainActor
    func testFromValuesProfile() {
        var profile = ValuesProfile.empty()
        var entry = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "Support",
            keywords: ["loyalty"],
            importance: 5
        )
        profile.updateEntry(entry)
        
        let profileData = ValuesProfileData.from(profile, context: modelContext)
        
        XCTAssertEqual(profileData.id, profile.id)
        XCTAssertEqual(profileData.entries.count, 10) // All categories from empty profile
        let friendsEntry = profileData.entries.first { $0.categoryRaw == "friends" }!
        XCTAssertEqual(friendsEntry.whatMatters, "Support")
        XCTAssertEqual(friendsEntry.keywords, ["loyalty"])
        XCTAssertEqual(friendsEntry.importance, 5)
    }
    
    @MainActor
    func testFromValuesProfileUpdatesExisting() {
        let existingData = ValuesProfileData(id: "existing_id")
        modelContext.insert(existingData)
        
        let existingEntry = existingData.entry(for: .friends)
        existingEntry.whatMatters = "Old"
        
        var profile = ValuesProfile(id: "existing_id", entries: [:])
        var entry = ValuesCategoryEntry(category: .friends, whatMatters: "New")
        profile.updateEntry(entry)
        
        let profileData = ValuesProfileData.from(profile, context: modelContext)
        
        XCTAssertEqual(profileData.id, "existing_id")
        let friendsEntry = profileData.entries.first { $0.categoryRaw == "friends" }!
        XCTAssertEqual(friendsEntry.whatMatters, "New")
    }
    
    // MARK: - ValuesCategoryEntryData Tests
    
    @MainActor
    func testValuesCategoryEntryDataCreation() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entryData = ValuesCategoryEntryData(
            category: .friends,
            whatMatters: "Support",
            whyItMatters: "Important",
            howToShowUp: "Be there",
            keywords: ["loyalty", "trust"],
            importance: 5
        )
        
        XCTAssertEqual(entryData.category, .friends)
        XCTAssertEqual(entryData.categoryRaw, "friends")
        XCTAssertEqual(entryData.whatMatters, "Support")
        XCTAssertEqual(entryData.whyItMatters, "Important")
        XCTAssertEqual(entryData.howToShowUp, "Be there")
        XCTAssertEqual(entryData.keywords, ["loyalty", "trust"])
        XCTAssertEqual(entryData.importance, 5)
    }
    
    @MainActor
    func testValuesCategoryEntryDataKeywordsGetterSetter() {
        let entryData = ValuesCategoryEntryData(category: .friends)
        
        entryData.keywords = ["loyalty", "trust"]
        XCTAssertEqual(entryData.keywords, ["loyalty", "trust"])
        
        entryData.keywords = []
        XCTAssertTrue(entryData.keywords.isEmpty)
    }
    
    @MainActor
    func testValuesCategoryEntryDataCategoryGetterSetter() {
        let entryData = ValuesCategoryEntryData(category: .friends)
        
        XCTAssertEqual(entryData.category, .friends)
        XCTAssertEqual(entryData.categoryRaw, "friends")
        
        entryData.category = .romanticRelationships
        XCTAssertEqual(entryData.category, .romanticRelationships)
        XCTAssertEqual(entryData.categoryRaw, "romantic_relationships")
    }
    
    @MainActor
    func testValuesCategoryEntryDataToValuesCategoryEntry() {
        let entryData = ValuesCategoryEntryData(
            category: .friends,
            whatMatters: "Support",
            whyItMatters: "Important",
            howToShowUp: "Be there",
            keywords: ["loyalty"],
            importance: 5
        )
        
        let entry = entryData.toValuesCategoryEntry()
        
        XCTAssertEqual(entry.id, entryData.id)
        XCTAssertEqual(entry.category, .friends)
        XCTAssertEqual(entry.whatMatters, "Support")
        XCTAssertEqual(entry.whyItMatters, "Important")
        XCTAssertEqual(entry.howToShowUp, "Be there")
        XCTAssertEqual(entry.keywords, ["loyalty"])
        XCTAssertEqual(entry.importance, 5)
    }
    
    @MainActor
    func testValuesCategoryEntryDataFromValuesCategoryEntry() {
        let profileData = ValuesProfileData()
        modelContext.insert(profileData)
        
        let entry = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "Support",
            keywords: ["loyalty"],
            importance: 5
        )
        
        let entryData = ValuesCategoryEntryData.from(entry, profile: profileData)
        
        XCTAssertEqual(entryData.id, entry.id)
        XCTAssertEqual(entryData.category, .friends)
        XCTAssertEqual(entryData.whatMatters, "Support")
        XCTAssertEqual(entryData.keywords, ["loyalty"])
        XCTAssertEqual(entryData.importance, 5)
        XCTAssertEqual(entryData.profile?.id, profileData.id)
    }
    
    @MainActor
    func testValuesCategoryEntryDataHasContent() {
        let emptyEntry = ValuesCategoryEntryData(category: .friends)
        XCTAssertFalse(emptyEntry.hasContent)
        
        let withWhatMatters = ValuesCategoryEntryData(category: .friends, whatMatters: "Support")
        XCTAssertTrue(withWhatMatters.hasContent)
        
        let withWhyItMatters = ValuesCategoryEntryData(category: .friends, whyItMatters: "Important")
        XCTAssertTrue(withWhyItMatters.hasContent)
        
        let withHowToShowUp = ValuesCategoryEntryData(category: .friends, howToShowUp: "Be there")
        XCTAssertTrue(withHowToShowUp.hasContent)
        
        let withKeywords = ValuesCategoryEntryData(category: .friends, keywords: ["loyalty"])
        XCTAssertTrue(withKeywords.hasContent)
        
        let withWhitespace = ValuesCategoryEntryData(category: .friends, whatMatters: "   ")
        XCTAssertFalse(withWhitespace.hasContent)
    }
}
