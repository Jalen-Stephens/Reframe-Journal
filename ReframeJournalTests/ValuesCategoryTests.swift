import XCTest
@testable import ReframeJournal

final class ValuesCategoryTests: XCTestCase {
    
    func testAllCategoriesExist() {
        XCTAssertEqual(ValuesCategory.allCases.count, 10)
        
        let categories = ValuesCategory.allCases
        XCTAssertTrue(categories.contains(.romanticRelationships))
        XCTAssertTrue(categories.contains(.leisureAndFun))
        XCTAssertTrue(categories.contains(.jobCareer))
        XCTAssertTrue(categories.contains(.friends))
        XCTAssertTrue(categories.contains(.parenthood))
        XCTAssertTrue(categories.contains(.healthAndWellness))
        XCTAssertTrue(categories.contains(.socialCitizenship))
        XCTAssertTrue(categories.contains(.familyRelationships))
        XCTAssertTrue(categories.contains(.spirituality))
        XCTAssertTrue(categories.contains(.personalGrowth))
    }
    
    func testCategoryTitles() {
        XCTAssertEqual(ValuesCategory.romanticRelationships.title, "Romantic Relationships")
        XCTAssertEqual(ValuesCategory.leisureAndFun.title, "Leisure & Fun")
        XCTAssertEqual(ValuesCategory.jobCareer.title, "Job / Career")
        XCTAssertEqual(ValuesCategory.friends.title, "Friends")
        XCTAssertEqual(ValuesCategory.parenthood.title, "Parenthood")
        XCTAssertEqual(ValuesCategory.healthAndWellness.title, "Health & Wellness")
        XCTAssertEqual(ValuesCategory.socialCitizenship.title, "Social Citizenship")
        XCTAssertEqual(ValuesCategory.familyRelationships.title, "Family Relationships")
        XCTAssertEqual(ValuesCategory.spirituality.title, "Spirituality")
        XCTAssertEqual(ValuesCategory.personalGrowth.title, "Personal Growth")
    }
    
    func testCategoryDescriptions() {
        XCTAssertFalse(ValuesCategory.romanticRelationships.description.isEmpty)
        XCTAssertFalse(ValuesCategory.leisureAndFun.description.isEmpty)
        XCTAssertFalse(ValuesCategory.jobCareer.description.isEmpty)
        XCTAssertFalse(ValuesCategory.friends.description.isEmpty)
        XCTAssertFalse(ValuesCategory.parenthood.description.isEmpty)
        XCTAssertFalse(ValuesCategory.healthAndWellness.description.isEmpty)
        XCTAssertFalse(ValuesCategory.socialCitizenship.description.isEmpty)
        XCTAssertFalse(ValuesCategory.familyRelationships.description.isEmpty)
        XCTAssertFalse(ValuesCategory.spirituality.description.isEmpty)
        XCTAssertFalse(ValuesCategory.personalGrowth.description.isEmpty)
    }
    
    func testCategoryIconNames() {
        XCTAssertEqual(ValuesCategory.romanticRelationships.iconName, "heart.fill")
        XCTAssertEqual(ValuesCategory.leisureAndFun.iconName, "sparkles")
        XCTAssertEqual(ValuesCategory.jobCareer.iconName, "briefcase.fill")
        XCTAssertEqual(ValuesCategory.friends.iconName, "person.2.fill")
        XCTAssertEqual(ValuesCategory.parenthood.iconName, "figure.2.and.child.holdinghands")
        XCTAssertEqual(ValuesCategory.healthAndWellness.iconName, "heart.text.square.fill")
        XCTAssertEqual(ValuesCategory.socialCitizenship.iconName, "globe.americas.fill")
        XCTAssertEqual(ValuesCategory.familyRelationships.iconName, "house.fill")
        XCTAssertEqual(ValuesCategory.spirituality.iconName, "moon.stars.fill")
        XCTAssertEqual(ValuesCategory.personalGrowth.iconName, "chart.line.uptrend.xyaxis")
    }
    
    func testCategoryRawValue() {
        XCTAssertEqual(ValuesCategory.romanticRelationships.rawValue, "romantic_relationships")
        XCTAssertEqual(ValuesCategory.leisureAndFun.rawValue, "leisure_and_fun")
        XCTAssertEqual(ValuesCategory.jobCareer.rawValue, "job_career")
    }
    
    func testCategoryInitFromRawValue() {
        XCTAssertEqual(ValuesCategory(rawValue: "romantic_relationships"), .romanticRelationships)
        XCTAssertEqual(ValuesCategory(rawValue: "personal_growth"), .personalGrowth)
        XCTAssertNil(ValuesCategory(rawValue: "invalid_category"))
    }
    
    func testCategoryId() {
        let category = ValuesCategory.romanticRelationships
        XCTAssertEqual(category.id, category.rawValue)
    }
    
    func testCategoryCodable() throws {
        let category = ValuesCategory.personalGrowth
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(category)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValuesCategory.self, from: data)
        
        XCTAssertEqual(decoded, category)
    }
    
    func testCategoryHashable() {
        let category1 = ValuesCategory.romanticRelationships
        let category2 = ValuesCategory.romanticRelationships
        let category3 = ValuesCategory.leisureAndFun
        
        var set = Set<ValuesCategory>()
        set.insert(category1)
        set.insert(category2)
        set.insert(category3)
        
        XCTAssertEqual(set.count, 2) // category1 and category2 are equal
    }
    
    // MARK: - ValuesCategoryEntry Tests
    
    func testValuesCategoryEntryCreation() {
        let entry = ValuesCategoryEntry(
            category: .romanticRelationships,
            whatMatters: "Connection",
            whyItMatters: "It's important to me",
            howToShowUp: "Be present",
            keywords: ["love", "trust"],
            importance: 5
        )
        
        XCTAssertEqual(entry.category, .romanticRelationships)
        XCTAssertEqual(entry.whatMatters, "Connection")
        XCTAssertEqual(entry.whyItMatters, "It's important to me")
        XCTAssertEqual(entry.howToShowUp, "Be present")
        XCTAssertEqual(entry.keywords, ["love", "trust"])
        XCTAssertEqual(entry.importance, 5)
        XCTAssertTrue(entry.id.hasPrefix("id_"))
    }
    
    func testValuesCategoryEntryEmpty() {
        let entry = ValuesCategoryEntry.empty(for: .friends)
        
        XCTAssertEqual(entry.category, .friends)
        XCTAssertTrue(entry.whatMatters.isEmpty)
        XCTAssertTrue(entry.whyItMatters.isEmpty)
        XCTAssertTrue(entry.howToShowUp.isEmpty)
        XCTAssertTrue(entry.keywords.isEmpty)
        XCTAssertNil(entry.importance)
    }
    
    func testValuesCategoryEntryHasContent() {
        let emptyEntry = ValuesCategoryEntry.empty(for: .friends)
        XCTAssertFalse(emptyEntry.hasContent)
        
        let entryWithWhatMatters = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "Support"
        )
        XCTAssertTrue(entryWithWhatMatters.hasContent)
        
        let entryWithWhyItMatters = ValuesCategoryEntry(
            category: .friends,
            whyItMatters: "Because it matters"
        )
        XCTAssertTrue(entryWithWhyItMatters.hasContent)
        
        let entryWithHowToShowUp = ValuesCategoryEntry(
            category: .friends,
            howToShowUp: "Be there"
        )
        XCTAssertTrue(entryWithHowToShowUp.hasContent)
        
        let entryWithKeywords = ValuesCategoryEntry(
            category: .friends,
            keywords: ["loyalty"]
        )
        XCTAssertTrue(entryWithKeywords.hasContent)
        
        let entryWithWhitespace = ValuesCategoryEntry(
            category: .friends,
            whatMatters: "   "
        )
        XCTAssertFalse(entryWithWhitespace.hasContent)
    }
    
    func testValuesCategoryEntrySummaryText() {
        let entryWithHowToShowUp = ValuesCategoryEntry(
            category: .friends,
            howToShowUp: "Be supportive and present for my friends when they need me"
        )
        XCTAssertNotNil(entryWithHowToShowUp.summaryText)
        XCTAssertTrue(entryWithHowToShowUp.summaryText?.contains("Be supportive") ?? false)
        
        let entryWithLongText = ValuesCategoryEntry(
            category: .friends,
            howToShowUp: String(repeating: "a", count: 100)
        )
        XCTAssertNotNil(entryWithLongText.summaryText)
        XCTAssertTrue(entryWithLongText.summaryText?.hasSuffix("…") ?? false)
        
        let emptyEntry = ValuesCategoryEntry.empty(for: .friends)
        XCTAssertNil(emptyEntry.summaryText)
    }
    
    func testValuesCategoryEntryCodable() throws {
        let entry = ValuesCategoryEntry(
            category: .personalGrowth,
            whatMatters: "Learning",
            whyItMatters: "Growth",
            howToShowUp: "Practice",
            keywords: ["growth", "learning"],
            importance: 4
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ValuesCategoryEntry.self, from: data)
        
        XCTAssertEqual(decoded.category, entry.category)
        XCTAssertEqual(decoded.whatMatters, entry.whatMatters)
        XCTAssertEqual(decoded.whyItMatters, entry.whyItMatters)
        XCTAssertEqual(decoded.howToShowUp, entry.howToShowUp)
        XCTAssertEqual(decoded.keywords, entry.keywords)
        XCTAssertEqual(decoded.importance, entry.importance)
    }
    
    func testValuesCategoryEntryEquatable() {
        let id = "test_id"
        let entry1 = ValuesCategoryEntry(
            id: id,
            category: .friends,
            whatMatters: "Support"
        )
        let entry2 = ValuesCategoryEntry(
            id: id,
            category: .friends,
            whatMatters: "Support"
        )
        let entry3 = ValuesCategoryEntry(
            id: "other_id",
            category: .friends,
            whatMatters: "Support"
        )
        
        XCTAssertEqual(entry1, entry2)
        XCTAssertNotEqual(entry1, entry3)
    }
}
