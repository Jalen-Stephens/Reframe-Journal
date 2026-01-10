import XCTest
@testable import ReframeJournal

final class ThoughtModelTests: XCTestCase {
    
    // MARK: - Thought Initialization Tests
    
    func testThoughtInitializationWithDefaults() {
        let thought = Thought(text: "Test thought")
        
        XCTAssertNotEqual(thought.id, UUID())
        XCTAssertEqual(thought.text, "Test thought")
        XCTAssertNil(thought.reframeResponse)
    }
    
    func testThoughtInitializationWithAllParameters() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1700000000)
        let response = ReframeResponse(
            summary: "Summary",
            cognitiveDistortionsDetected: ["Distortion"],
            alternativeThoughts: ["Alternative"],
            actionSteps: ["Step"],
            compassionateCoachMessage: "Message",
            suggestedExperiment: "Experiment"
        )
        
        let thought = Thought(id: id, createdAt: date, text: "Text", reframeResponse: response)
        
        XCTAssertEqual(thought.id, id)
        XCTAssertEqual(thought.createdAt, date)
        XCTAssertEqual(thought.text, "Text")
        XCTAssertEqual(thought.reframeResponse?.summary, "Summary")
    }
    
    // MARK: - Thought Equatable Tests
    
    func testThoughtEquality() {
        let id = UUID()
        let date = Date()
        
        let thought1 = Thought(id: id, createdAt: date, text: "Same", reframeResponse: nil)
        let thought2 = Thought(id: id, createdAt: date, text: "Same", reframeResponse: nil)
        
        XCTAssertEqual(thought1, thought2)
    }
    
    func testThoughtInequalityDifferentText() {
        let id = UUID()
        let date = Date()
        
        let thought1 = Thought(id: id, createdAt: date, text: "Text1", reframeResponse: nil)
        let thought2 = Thought(id: id, createdAt: date, text: "Text2", reframeResponse: nil)
        
        XCTAssertNotEqual(thought1, thought2)
    }
    
    // MARK: - Thought Identifiable Tests
    
    func testThoughtIsIdentifiable() {
        let thought = Thought(text: "Test")
        XCTAssertNotNil(thought.id)
    }
    
    // MARK: - Thought Codable Tests
    
    func testThoughtEncodingDecoding() throws {
        let original = Thought(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1700000000),
            text: "Test thought",
            reframeResponse: nil
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Thought.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.text, original.text)
    }
    
    func testThoughtEncodingDecodingWithResponse() throws {
        let response = ReframeResponse(
            summary: "Summary",
            cognitiveDistortionsDetected: ["Distortion1", "Distortion2"],
            alternativeThoughts: ["Alt1"],
            actionSteps: ["Step1", "Step2"],
            compassionateCoachMessage: "Be kind",
            suggestedExperiment: "Try this"
        )
        
        let original = Thought(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1700000000),
            text: "Test",
            reframeResponse: response
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Thought.self, from: data)
        
        XCTAssertEqual(decoded.reframeResponse?.summary, "Summary")
        XCTAssertEqual(decoded.reframeResponse?.cognitiveDistortionsDetected.count, 2)
    }
}

// MARK: - AutomaticThought Tests

final class AutomaticThoughtTests: XCTestCase {
    
    func testAutomaticThoughtInitialization() {
        let thought = AutomaticThought(id: "t1", text: "I'm failing", beliefBefore: 85)
        
        XCTAssertEqual(thought.id, "t1")
        XCTAssertEqual(thought.text, "I'm failing")
        XCTAssertEqual(thought.beliefBefore, 85)
    }
    
    func testAutomaticThoughtHashable() {
        let thought1 = AutomaticThought(id: "t1", text: "Same", beliefBefore: 50)
        let thought2 = AutomaticThought(id: "t1", text: "Same", beliefBefore: 50)
        let thought3 = AutomaticThought(id: "t2", text: "Different", beliefBefore: 60)
        
        XCTAssertEqual(thought1, thought2)
        XCTAssertNotEqual(thought1, thought3)
    }
    
    func testAutomaticThoughtCodable() throws {
        let original = AutomaticThought(id: "test_id", text: "Test thought", beliefBefore: 70)
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AutomaticThought.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.text, original.text)
        XCTAssertEqual(decoded.beliefBefore, original.beliefBefore)
    }
}

// MARK: - Emotion Tests

final class EmotionTests: XCTestCase {
    
    func testEmotionInitialization() {
        let emotion = Emotion(id: "e1", label: "Anxious", intensityBefore: 70, intensityAfter: 40)
        
        XCTAssertEqual(emotion.id, "e1")
        XCTAssertEqual(emotion.label, "Anxious")
        XCTAssertEqual(emotion.intensityBefore, 70)
        XCTAssertEqual(emotion.intensityAfter, 40)
    }
    
    func testEmotionWithNilIntensityAfter() {
        let emotion = Emotion(id: "e1", label: "Happy", intensityBefore: 80, intensityAfter: nil)
        
        XCTAssertNil(emotion.intensityAfter)
    }
    
    func testEmotionCodable() throws {
        let original = Emotion(id: "test", label: "Sad", intensityBefore: 60, intensityAfter: 30)
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Emotion.self, from: data)
        
        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.label, original.label)
        XCTAssertEqual(decoded.intensityBefore, original.intensityBefore)
        XCTAssertEqual(decoded.intensityAfter, original.intensityAfter)
    }
}

// MARK: - ThoughtOutcome Tests

final class ThoughtOutcomeTests: XCTestCase {
    
    func testThoughtOutcomeInitialization() {
        let outcome = ThoughtOutcome(
            beliefAfter: 30,
            emotionsAfter: ["e1": 40, "e2": 50],
            reflection: "I feel better",
            isComplete: true
        )
        
        XCTAssertEqual(outcome.beliefAfter, 30)
        XCTAssertEqual(outcome.emotionsAfter["e1"], 40)
        XCTAssertEqual(outcome.emotionsAfter["e2"], 50)
        XCTAssertEqual(outcome.reflection, "I feel better")
        XCTAssertTrue(outcome.isComplete)
    }
    
    func testThoughtOutcomeCodable() throws {
        let original = ThoughtOutcome(
            beliefAfter: 45,
            emotionsAfter: ["emotion1": 35],
            reflection: "Reflection text",
            isComplete: false
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ThoughtOutcome.self, from: data)
        
        XCTAssertEqual(decoded.beliefAfter, original.beliefAfter)
        XCTAssertEqual(decoded.emotionsAfter, original.emotionsAfter)
        XCTAssertEqual(decoded.reflection, original.reflection)
        XCTAssertEqual(decoded.isComplete, original.isComplete)
    }
}

// MARK: - AdaptiveResponsesForThought Tests

final class AdaptiveResponsesForThoughtTests: XCTestCase {
    
    func testAdaptiveResponsesInitialization() {
        let responses = AdaptiveResponsesForThought(
            evidenceText: "Evidence here",
            evidenceBelief: 40,
            alternativeText: "Alternative here",
            alternativeBelief: 60,
            outcomeText: "Outcome here",
            outcomeBelief: 50,
            friendText: "Friend would say",
            friendBelief: 70
        )
        
        XCTAssertEqual(responses.evidenceText, "Evidence here")
        XCTAssertEqual(responses.evidenceBelief, 40)
        XCTAssertEqual(responses.alternativeText, "Alternative here")
        XCTAssertEqual(responses.alternativeBelief, 60)
        XCTAssertEqual(responses.outcomeText, "Outcome here")
        XCTAssertEqual(responses.outcomeBelief, 50)
        XCTAssertEqual(responses.friendText, "Friend would say")
        XCTAssertEqual(responses.friendBelief, 70)
    }
    
    func testAdaptiveResponsesCodable() throws {
        let original = AdaptiveResponsesForThought(
            evidenceText: "E",
            evidenceBelief: 1,
            alternativeText: "A",
            alternativeBelief: 2,
            outcomeText: "O",
            outcomeBelief: 3,
            friendText: "F",
            friendBelief: 4
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AdaptiveResponsesForThought.self, from: data)
        
        XCTAssertEqual(decoded, original)
    }
}
