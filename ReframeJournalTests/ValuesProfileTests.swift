import XCTest
@testable import ReframeJournal

final class ValuesProfileTests: XCTestCase {
    
    func testValuesProfileCreation() {
        let profile = ValuesProfile(
            id: "test_id",
            entries: [:],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 1)
        )
        
        XCTAssertEqual(profile.id, "test_id")
        XCTAssertTrue(profile.entries.isEmpty)
        XCTAssertNotNil(profile.createdAt)
        XCTAssertNotNil(profile.updatedAt)
    }
    
    func testValuesProfileDefaultInit() {
        let profile = ValuesProfile()
        
        XCTAssertTrue(profile.id.hasPrefix("id_"))
        XCTAssertTrue(profile.entries.isEmpty)
        XCTAssertNotNil(profile.createdAt)
        XCTAssertNotNil(profile.updatedAt)
    }
    
    func testValuesProfileEmpty() {
        let profile = ValuesProfile.empty()
        
        XCTAssertEqual(profile.entries.count, 10) // All 10 categories should have entries
        XCTAssertTrue(profile.entries.keys.contains(.romanticRelationships))
        XCTAssertTrue(profile.entries.keys.contains(.leisureAndFun))
        XCTAssertTrue(profile.entries.keys.contains(.jobCareer))
        XCTAssertTrue(profile.entries.keys.contains(.friends))
        XCTAssertTrue(profile.entries.keys.contains(.parenthood))
        XCTAssertTrue(profile.entries.keys.contains(.healthAndWellness))
        XCTAssertTrue(profile.entries.keys.contains(.socialCitizenship))
        XCTAssertTrue(profile.entries.keys.contains(.familyRelationships))
        XCTAssertTrue(profile.entries.keys.contains(.spirituality))
        XCTAssertTrue(profile.entries.keys.contains(.personalGrowth))
        
        // All entries should be empty
        for entry in profile.entries.values {
            XCTAssertFalse(entry.hasContent)
        }
    }
    
    func testEntryForCategory() {
        var profile = ValuesProfile.empty()
        
        let entry = profile.entry(for: .friends)
        XCTAssertEqual(entry.category, .friends)
        XCTAssertFalse(entry.hasContent)
        
        // Update entry
        var updatedEntry = entry
        updatedEntry.whatMatters = "Support"
        profile.updateEntry(updatedEntry)
        
        let retrievedEntry = profile.entry(for: .friends)
        XCTAssertEqual(retrievedEntry.whatMatters, "Support")
    }
    
    func testUpdateEntry() {
        var profile = ValuesProfile.empty()
        let now = Date()
        
        var entry = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "Loyalty",
            whyItMatters: "Trust is important",
            howToShowUp: "Be there",
            keywords: ["loyalty", "trust"],
            importance: 5,
            updatedAt: now
        )
        
        profile.updateEntry(entry)
        
        let updatedEntry = profile.entries[.friends]
        XCTAssertNotNil(updatedEntry)
        XCTAssertEqual(updatedEntry?.whatMatters, "Loyalty")
        XCTAssertEqual(updatedEntry?.whyItMatters, "Trust is important")
        XCTAssertEqual(updatedEntry?.howToShowUp, "Be there")
        XCTAssertEqual(updatedEntry?.keywords, ["loyalty", "trust"])
        XCTAssertEqual(updatedEntry?.importance, 5)
        XCTAssertTrue(profile.updatedAt >= now)
    }
    
    func testCategoriesWithContent() {
        var profile = ValuesProfile.empty()
        
        XCTAssertTrue(profile.categoriesWithContent.isEmpty)
        
        var entry1 = ValuesCategoryEntry(category: .friends, whatMatters: "Support")
        profile.updateEntry(entry1)
        
        var entry2 = ValuesCategoryEntry(category: .romanticRelationships, whatMatters: "Love", importance: 5)
        profile.updateEntry(entry2)
        
        var entry3 = ValuesCategoryEntry(category: .jobCareer, whatMatters: "Growth", importance: 3)
        profile.updateEntry(entry3)
        
        let categoriesWithContent = profile.categoriesWithContent
        XCTAssertEqual(categoriesWithContent.count, 3)
        // Should be sorted by importance (highest first)
        XCTAssertEqual(categoriesWithContent.first, .romanticRelationships) // importance 5
        XCTAssertEqual(categoriesWithContent[1], .jobCareer) // importance 3
        XCTAssertEqual(categoriesWithContent.last, .friends) // no importance (nil)
    }
    
    func testTopCategories() {
        var profile = ValuesProfile.empty()
        
        XCTAssertTrue(profile.topCategories.isEmpty)
        
        // Add more than 3 categories with content
        var entry1 = ValuesCategoryEntry(category: .friends, whatMatters: "Support", importance: 5)
        profile.updateEntry(entry1)
        
        var entry2 = ValuesCategoryEntry(category: .romanticRelationships, whatMatters: "Love", importance: 4)
        profile.updateEntry(entry2)
        
        var entry3 = ValuesCategoryEntry(category: .jobCareer, whatMatters: "Growth", importance: 3)
        profile.updateEntry(entry3)
        
        var entry4 = ValuesCategoryEntry(category: .healthAndWellness, whatMatters: "Fitness", importance: 2)
        profile.updateEntry(entry4)
        
        let topCategories = profile.topCategories
        XCTAssertEqual(topCategories.count, 3)
        XCTAssertEqual(topCategories[0], .friends) // importance 5
        XCTAssertEqual(topCategories[1], .romanticRelationships) // importance 4
        XCTAssertEqual(topCategories[2], .jobCareer) // importance 3
    }
    
    func testHasContent() {
        var profile = ValuesProfile.empty()
        XCTAssertFalse(profile.hasContent)
        
        var entry = ValuesCategoryEntry(category: .friends, whatMatters: "Support")
        profile.updateEntry(entry)
        XCTAssertTrue(profile.hasContent)
    }
    
    func testAllKeywords() {
        var profile = ValuesProfile.empty()
        XCTAssertTrue(profile.allKeywords.isEmpty)
        
        var entry1 = ValuesCategoryEntry(category: .friends, keywords: ["loyalty", "trust"])
        profile.updateEntry(entry1)
        
        var entry2 = ValuesCategoryEntry(category: .romanticRelationships, keywords: ["love", "connection"])
        profile.updateEntry(entry2)
        
        let allKeywords = profile.allKeywords
        XCTAssertEqual(allKeywords.count, 4)
        XCTAssertTrue(allKeywords.contains("loyalty"))
        XCTAssertTrue(allKeywords.contains("trust"))
        XCTAssertTrue(allKeywords.contains("love"))
        XCTAssertTrue(allKeywords.contains("connection"))
    }
    
    func testCompletionProgress() {
        var profile = ValuesProfile.empty()
        XCTAssertEqual(profile.completionProgress, 0.0, accuracy: 0.01)
        
        var entry1 = ValuesCategoryEntry(category: .friends, whatMatters: "Support")
        profile.updateEntry(entry1)
        XCTAssertEqual(profile.completionProgress, 0.1, accuracy: 0.01) // 1/10
        
        var entry2 = ValuesCategoryEntry(category: .romanticRelationships, whatMatters: "Love")
        profile.updateEntry(entry2)
        XCTAssertEqual(profile.completionProgress, 0.2, accuracy: 0.01) // 2/10
        
        // All 10 categories filled
        for category in ValuesCategory.allCases {
            var entry = ValuesCategoryEntry(category: category, whatMatters: "Content")
            profile.updateEntry(entry)
        }
        XCTAssertEqual(profile.completionProgress, 1.0, accuracy: 0.01) // 10/10
    }
    
    func testValuesProfileCodable() throws {
        var profile = ValuesProfile.empty()
        var entry = ValuesCategoryEntry(category: .friends, whatMatters: "Support", keywords: ["loyalty"])
        profile.updateEntry(entry)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValuesProfile.self, from: data)
        
        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.entries.count, profile.entries.count)
        XCTAssertEqual(decoded.entry(for: .friends).whatMatters, "Support")
    }
    
    func testValuesProfileEquatable() {
        let id = "test_id"
        let date = Date(timeIntervalSince1970: 0)
        let profile1 = ValuesProfile(id: id, entries: [:], createdAt: date, updatedAt: date)
        let profile2 = ValuesProfile(id: id, entries: [:], createdAt: date, updatedAt: date)
        let profile3 = ValuesProfile(id: "other_id", entries: [:], createdAt: date, updatedAt: date)
        
        XCTAssertEqual(profile1, profile2)
        XCTAssertNotEqual(profile1, profile3)
    }
    
    // MARK: - SelectedValues Tests
    
    func testSelectedValuesCreation() {
        let selected = SelectedValues(
            categories: [.friends, .romanticRelationships],
            keywords: ["loyalty", "trust"],
            howToShowUp: "Be present"
        )
        
        XCTAssertEqual(selected.categories.count, 2)
        XCTAssertEqual(selected.keywords.count, 2)
        XCTAssertEqual(selected.howToShowUp, "Be present")
    }
    
    func testSelectedValuesEmpty() {
        let selected = SelectedValues.empty
        
        XCTAssertTrue(selected.categories.isEmpty)
        XCTAssertTrue(selected.keywords.isEmpty)
        XCTAssertTrue(selected.howToShowUp.isEmpty)
        XCTAssertFalse(selected.hasSelection)
    }
    
    func testSelectedValuesHasSelection() {
        let empty = SelectedValues()
        XCTAssertFalse(empty.hasSelection)
        
        let withCategories = SelectedValues(categories: [.friends])
        XCTAssertTrue(withCategories.hasSelection)
        
        let withKeywords = SelectedValues(keywords: ["loyalty"])
        XCTAssertTrue(withKeywords.hasSelection)
        
        let withHowToShowUp = SelectedValues(howToShowUp: "Be present")
        XCTAssertTrue(withHowToShowUp.hasSelection)
        
        let withWhitespace = SelectedValues(howToShowUp: "   ")
        XCTAssertFalse(withWhitespace.hasSelection)
    }
    
    func testSelectedValuesSummaryText() {
        let withCategories = SelectedValues(categories: [.friends, .romanticRelationships])
        XCTAssertNotNil(withCategories.summaryText)
        XCTAssertTrue(withCategories.summaryText?.contains("Friends") ?? false)
        
        let withMultipleCategories = SelectedValues(
            categories: [.friends, .romanticRelationships, .jobCareer, .healthAndWellness]
        )
        let summary = withMultipleCategories.summaryText ?? ""
        XCTAssertTrue(summary.contains("Friends"))
        XCTAssertTrue(summary.contains("+2")) // Shows "+2" for additional categories
        
        let withKeywords = SelectedValues(keywords: ["loyalty", "trust", "love"])
        XCTAssertNotNil(withKeywords.summaryText)
        XCTAssertTrue(withKeywords.summaryText?.contains("loyalty") ?? false)
        
        let empty = SelectedValues()
        XCTAssertNil(empty.summaryText)
    }
    
    func testSelectedValuesCodable() throws {
        let selected = SelectedValues(
            categories: [.friends, .romanticRelationships],
            keywords: ["loyalty", "trust"],
            howToShowUp: "Be present"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(selected)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SelectedValues.self, from: data)
        
        XCTAssertEqual(decoded.categories, selected.categories)
        XCTAssertEqual(decoded.keywords, selected.keywords)
        XCTAssertEqual(decoded.howToShowUp, selected.howToShowUp)
    }
    
    // MARK: - ValuesProfileSnippet Tests
    
    func testValuesProfileSnippetCreation() {
        var profile = ValuesProfile.empty()
        var entry = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "What matters text",
            howToShowUp: "How to show up text"
        )
        profile.updateEntry(entry)
        
        let selection = SelectedValues(categories: [.friends], howToShowUp: "Be present")
        let snippet = ValuesProfileSnippet.create(from: selection, profile: profile)
        
        XCTAssertFalse(snippet.categories.isEmpty)
        XCTAssertEqual(snippet.howToShowUp, "Be present")
        XCTAssertTrue(snippet.hasContent)
    }
    
    func testValuesProfileSnippetHasContent() {
        let emptySnippet = ValuesProfileSnippet(
            categories: [],
            howToShowUp: "",
            keywords: []
        )
        XCTAssertFalse(emptySnippet.hasContent)
        
        let withCategories = ValuesProfileSnippet(
            categories: [ValuesProfileSnippet.CategorySnippet(title: "Friends", whatMatters: "Support", howToShowUp: "Be there")],
            howToShowUp: "",
            keywords: []
        )
        XCTAssertTrue(withCategories.hasContent)
        
        let withHowToShowUp = ValuesProfileSnippet(
            categories: [],
            howToShowUp: "Be present",
            keywords: []
        )
        XCTAssertTrue(withHowToShowUp.hasContent)
        
        let withKeywords = ValuesProfileSnippet(
            categories: [],
            howToShowUp: "",
            keywords: ["loyalty"]
        )
        XCTAssertTrue(withKeywords.hasContent)
    }
    
    func testValuesProfileSnippetTruncation() {
        var profile = ValuesProfile.empty()
        let longText = String(repeating: "a", count: 300)
        var entry = ValuesCategoryEntry(category: .friends, whatMatters: longText)
        profile.updateEntry(entry)
        
        let selection = SelectedValues(categories: [.friends])
        let snippet = ValuesProfileSnippet.create(from: selection, profile: profile, maxCharsPerField: 200)
        
        let categorySnippet = snippet.categories.first!
        XCTAssertLessThanOrEqual(categorySnippet.whatMatters.count, 201) // 200 + "…"
        XCTAssertTrue(categorySnippet.whatMatters.hasSuffix("…"))
    }
}
