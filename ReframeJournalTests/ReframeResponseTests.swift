import XCTest
@testable import ReframeJournal

final class ReframeResponseTests: XCTestCase {
    
    func testReframeResponseCreation() {
        let response = ReframeResponse(
            summary: "Test summary",
            cognitiveDistortionsDetected: ["Catastrophizing", "Mind reading"],
            alternativeThoughts: ["Alternative 1", "Alternative 2"],
            actionSteps: ["Step 1", "Step 2"],
            compassionateCoachMessage: "You're doing great",
            suggestedExperiment: "Try this experiment"
        )
        
        XCTAssertEqual(response.summary, "Test summary")
        XCTAssertEqual(response.cognitiveDistortionsDetected.count, 2)
        XCTAssertEqual(response.alternativeThoughts.count, 2)
        XCTAssertEqual(response.actionSteps.count, 2)
        XCTAssertEqual(response.compassionateCoachMessage, "You're doing great")
        XCTAssertEqual(response.suggestedExperiment, "Try this experiment")
    }
    
    func testReframeResponseEquatable() {
        let response1 = ReframeResponse(
            summary: "Summary",
            cognitiveDistortionsDetected: ["Distortion"],
            alternativeThoughts: ["Alternative"],
            actionSteps: ["Step"],
            compassionateCoachMessage: "Message",
            suggestedExperiment: "Experiment"
        )
        
        let response2 = ReframeResponse(
            summary: "Summary",
            cognitiveDistortionsDetected: ["Distortion"],
            alternativeThoughts: ["Alternative"],
            actionSteps: ["Step"],
            compassionateCoachMessage: "Message",
            suggestedExperiment: "Experiment"
        )
        
        let response3 = ReframeResponse(
            summary: "Different Summary",
            cognitiveDistortionsDetected: ["Distortion"],
            alternativeThoughts: ["Alternative"],
            actionSteps: ["Step"],
            compassionateCoachMessage: "Message",
            suggestedExperiment: "Experiment"
        )
        
        XCTAssertEqual(response1, response2)
        XCTAssertNotEqual(response1, response3)
    }
    
    func testReframeResponseCodable() throws {
        let response = ReframeResponse(
            summary: "Test summary",
            cognitiveDistortionsDetected: ["Catastrophizing"],
            alternativeThoughts: ["Alternative thought"],
            actionSteps: ["Action step"],
            compassionateCoachMessage: "Compassionate message",
            suggestedExperiment: "Suggested experiment"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(response)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ReframeResponse.self, from: data)
        
        XCTAssertEqual(decoded.summary, response.summary)
        XCTAssertEqual(decoded.cognitiveDistortionsDetected, response.cognitiveDistortionsDetected)
        XCTAssertEqual(decoded.alternativeThoughts, response.alternativeThoughts)
        XCTAssertEqual(decoded.actionSteps, response.actionSteps)
        XCTAssertEqual(decoded.compassionateCoachMessage, response.compassionateCoachMessage)
        XCTAssertEqual(decoded.suggestedExperiment, response.suggestedExperiment)
    }
    
    func testReframeResponseWithEmptyArrays() {
        let response = ReframeResponse(
            summary: "Summary only",
            cognitiveDistortionsDetected: [],
            alternativeThoughts: [],
            actionSteps: [],
            compassionateCoachMessage: "",
            suggestedExperiment: ""
        )
        
        XCTAssertTrue(response.cognitiveDistortionsDetected.isEmpty)
        XCTAssertTrue(response.alternativeThoughts.isEmpty)
        XCTAssertTrue(response.actionSteps.isEmpty)
    }
}
