import XCTest
@testable import ReframeJournal

final class ThoughtTests: XCTestCase {
    
    func testThoughtCreation() {
        let id = UUID()
        let createdAt = Date()
        let thought = Thought(id: id, createdAt: createdAt, text: "Test thought")
        
        XCTAssertEqual(thought.id, id)
        XCTAssertEqual(thought.createdAt, createdAt)
        XCTAssertEqual(thought.text, "Test thought")
        XCTAssertNil(thought.reframeResponse)
    }
    
    func testThoughtDefaultInit() {
        let thought = Thought(text: "Test")
        
        XCTAssertNotNil(thought.id)
        XCTAssertNotNil(thought.createdAt)
        XCTAssertEqual(thought.text, "Test")
        XCTAssertNil(thought.reframeResponse)
    }
    
    func testThoughtWithReframeResponse() {
        let reframeResponse = ReframeResponse(
            summary: "Summary",
            cognitiveDistortionsDetected: ["Distortion"],
            alternativeThoughts: ["Alternative"],
            actionSteps: ["Step"],
            compassionateCoachMessage: "Message",
            suggestedExperiment: "Experiment"
        )
        
        let thought = Thought(text: "Test", reframeResponse: reframeResponse)
        
        XCTAssertNotNil(thought.reframeResponse)
        XCTAssertEqual(thought.reframeResponse?.summary, "Summary")
    }
    
    func testThoughtCodable() throws {
        let thought = Thought(text: "Test thought")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(thought)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Thought.self, from: data)
        
        XCTAssertEqual(decoded.id, thought.id)
        XCTAssertEqual(decoded.text, "Test thought")
    }
    
    func testThoughtEquatable() {
        let id = UUID()
        let createdAt = Date()
        let thought1 = Thought(id: id, createdAt: createdAt, text: "Same")
        let thought2 = Thought(id: id, createdAt: createdAt, text: "Same")
        let thought3 = Thought(id: UUID(), createdAt: createdAt, text: "Same")
        
        XCTAssertEqual(thought1, thought2)
        XCTAssertNotEqual(thought1, thought3)
    }
    
    func testThoughtIdentifiable() {
        let id = UUID()
        let thought = Thought(id: id, createdAt: Date(), text: "Test")
        XCTAssertEqual(thought.id, id)
    }
    
    func testThoughtMutability() {
        var thought = Thought(text: "Original")
        thought.text = "Updated"
        XCTAssertEqual(thought.text, "Updated")
        
        let reframeResponse = ReframeResponse(
            summary: "Summary",
            cognitiveDistortionsDetected: [],
            alternativeThoughts: [],
            actionSteps: [],
            compassionateCoachMessage: "",
            suggestedExperiment: ""
        )
        thought.reframeResponse = reframeResponse
        XCTAssertNotNil(thought.reframeResponse)
    }
}
