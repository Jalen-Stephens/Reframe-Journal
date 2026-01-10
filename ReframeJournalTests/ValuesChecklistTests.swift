import XCTest
@testable import ReframeJournal

final class ValuesChecklistTests: XCTestCase {
    
    func testAllValuesNotEmpty() {
        XCTAssertFalse(ValuesChecklist.allValues.isEmpty)
        XCTAssertGreaterThan(ValuesChecklist.allValues.count, 50)
    }
    
    func testValueItemStructure() {
        let acceptance = ValuesChecklist.allValues.first { $0.name == "Acceptance" }
        XCTAssertNotNil(acceptance)
        XCTAssertEqual(acceptance?.id, 1)
        XCTAssertEqual(acceptance?.name, "Acceptance")
        XCTAssertFalse(acceptance?.description.isEmpty ?? true)
    }
    
    func testSearchEmptyQuery() {
        let results = ValuesChecklist.search("")
        XCTAssertEqual(results.count, ValuesChecklist.allValues.count)
    }
    
    func testSearchWhitespaceOnly() {
        let results = ValuesChecklist.search("   ")
        XCTAssertEqual(results.count, ValuesChecklist.allValues.count)
    }
    
    func testSearchCaseInsensitive() {
        let lowerResults = ValuesChecklist.search("acceptance")
        let upperResults = ValuesChecklist.search("ACCEPTANCE")
        let mixedResults = ValuesChecklist.search("AcCePtAnCe")
        
        XCTAssertEqual(lowerResults.count, upperResults.count)
        XCTAssertEqual(lowerResults.count, mixedResults.count)
        XCTAssertGreaterThan(lowerResults.count, 0)
    }
    
    func testSearchPartialMatch() {
        let results = ValuesChecklist.search("accept")
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.name.lowercased().contains("accept") })
    }
    
    func testSearchNoMatch() {
        let results = ValuesChecklist.search("nonexistentvalue12345")
        XCTAssertTrue(results.isEmpty)
    }
    
    func testMatchingWithEmptyKeywords() {
        let results = ValuesChecklist.matching([])
        XCTAssertTrue(results.isEmpty)
    }
    
    func testMatchingWithSingleKeyword() {
        let results = ValuesChecklist.matching(["Acceptance"])
        XCTAssertGreaterThan(results.count, 0)
        XCTAssertTrue(results.allSatisfy { $0.name.lowercased() == "acceptance" })
    }
    
    func testMatchingWithMultipleKeywords() {
        let results = ValuesChecklist.matching(["Acceptance", "Adventure", "Authenticity"])
        XCTAssertGreaterThanOrEqual(results.count, 3)
        let names = Set(results.map { $0.name.lowercased() })
        XCTAssertTrue(names.contains("acceptance"))
        XCTAssertTrue(names.contains("adventure"))
        XCTAssertTrue(names.contains("authenticity"))
    }
    
    func testMatchingCaseInsensitive() {
        let lowerResults = ValuesChecklist.matching(["acceptance"])
        let upperResults = ValuesChecklist.matching(["ACCEPTANCE"])
        
        XCTAssertEqual(lowerResults.count, upperResults.count)
        XCTAssertGreaterThan(lowerResults.count, 0)
    }
    
    func testMatchingWithNonExistentKeywords() {
        let results = ValuesChecklist.matching(["NonexistentValue", "AnotherFakeValue"])
        XCTAssertTrue(results.isEmpty)
    }
    
    func testValueItemIdentifiable() {
        let value = ValuesChecklist.allValues.first!
        XCTAssertGreaterThan(value.id, 0)
    }
    
    func testValueItemHashable() {
        let value1 = ValuesChecklist.allValues[0]
        let value2 = ValuesChecklist.allValues[0]
        let value3 = ValuesChecklist.allValues[1]
        
        var set = Set<ValueItem>()
        set.insert(value1)
        set.insert(value2)
        set.insert(value3)
        
        XCTAssertEqual(set.count, 2) // value1 and value2 are equal
    }
    
    func testCommonValuesExist() {
        let commonNames = ["Acceptance", "Adventure", "Compassion", "Courage", "Gratitude", "Love", "Mindfulness"]
        let allNames = Set(ValuesChecklist.allValues.map { $0.name })
        
        for name in commonNames {
            XCTAssertTrue(allNames.contains(name), "Expected value '\(name)' not found")
        }
    }
}
