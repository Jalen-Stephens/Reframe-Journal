import XCTest
@testable import ReframeJournal

final class AIReframeDepthTests: XCTestCase {
    
    // MARK: - Enum Cases Tests
    
    func testAllCases() {
        let allCases = AIReframeDepth.allCases
        
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.quick))
        XCTAssertTrue(allCases.contains(.deep))
    }
    
    // MARK: - RawValue Tests
    
    func testRawValues() {
        XCTAssertEqual(AIReframeDepth.quick.rawValue, "quick")
        XCTAssertEqual(AIReframeDepth.deep.rawValue, "deep")
    }
    
    func testInitFromRawValue() {
        XCTAssertEqual(AIReframeDepth(rawValue: "quick"), .quick)
        XCTAssertEqual(AIReframeDepth(rawValue: "deep"), .deep)
        XCTAssertNil(AIReframeDepth(rawValue: "invalid"))
    }
    
    // MARK: - Identifiable Tests
    
    func testIdEqualsRawValue() {
        XCTAssertEqual(AIReframeDepth.quick.id, "quick")
        XCTAssertEqual(AIReframeDepth.deep.id, "deep")
    }
    
    // MARK: - Title Tests
    
    func testTitleValues() {
        XCTAssertEqual(AIReframeDepth.quick.title, "Quick")
        XCTAssertEqual(AIReframeDepth.deep.title, "Deep")
    }
    
    // MARK: - PromptLabel Tests
    
    func testPromptLabelValues() {
        XCTAssertEqual(AIReframeDepth.quick.promptLabel, "Quick")
        XCTAssertEqual(AIReframeDepth.deep.promptLabel, "Deep")
    }
    
    // MARK: - Codable Tests
    
    func testEncodingDecoding() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for depth in AIReframeDepth.allCases {
            let data = try encoder.encode(depth)
            let decoded = try decoder.decode(AIReframeDepth.self, from: data)
            XCTAssertEqual(decoded, depth)
        }
    }
    
    func testDecodingFromString() throws {
        let json = "\"quick\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AIReframeDepth.self, from: data)
        
        XCTAssertEqual(decoded, .quick)
    }
}
