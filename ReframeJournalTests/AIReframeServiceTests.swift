import XCTest
@testable import ReframeJournal

final class AIReframeServiceTests: XCTestCase {
    func testBuildUserMessageIncludesCoreFields() {
        let thought = AutomaticThought(id: "t1", text: "I always mess up", beliefBefore: 80)
        let emotion = Emotion(id: "e1", label: "Anxious", intensityBefore: 70, intensityAfter: nil)
        let responses = AdaptiveResponsesForThought(
            evidenceText: "I made a mistake once",
            evidenceBelief: 40,
            alternativeText: "I can learn from this",
            alternativeBelief: 60,
            outcomeText: "I felt a bit calmer",
            outcomeBelief: 55,
            friendText: "You are trying your best",
            friendBelief: 70
        )
        let outcome = ThoughtOutcome(
            beliefAfter: 50,
            emotionsAfter: [emotion.id: 40],
            reflection: "Noticed less tension",
            isComplete: true
        )

        let record = ThoughtRecord(
            id: "r1",
            createdAt: "2024-01-01T12:00:00Z",
            updatedAt: "2024-01-01T12:10:00Z",
            situationText: "Work presentation",
            sensations: ["tight chest"],
            automaticThoughts: [thought],
            emotions: [emotion],
            thinkingStyles: ["Catastrophizing"],
            adaptiveResponses: [thought.id: responses],
            outcomesByThought: [thought.id: outcome],
            beliefAfterMainThought: 55,
            notes: ""
        )

        let service = AIReframeService(clientProvider: { throw OpenAIClient.OpenAIError.missingAPIKey })
        let message = service.buildUserMessage(for: record)

        XCTAssertTrue(message.contains("Date/time: 2024-01-01T12:00:00Z"))
        XCTAssertTrue(message.contains("Situation: Work presentation"))
        XCTAssertTrue(message.contains("Emotions: Anxious (70%)"))
        XCTAssertTrue(message.contains("Physical sensations: tight chest"))
        XCTAssertTrue(message.contains("Automatic thoughts: I always mess up (belief 80%)"))
        XCTAssertTrue(message.contains("Cognitive distortions: Catastrophizing"))
        XCTAssertTrue(message.contains("Evidence for/against:"))
        XCTAssertTrue(message.contains("Alternative responses / adaptive responses:"))
        XCTAssertTrue(message.contains("Outcome / reflection:"))
    }

    func testAIReframeResultDecodesJSON() throws {
        let json = """
        {
          "reframe_summary": "You faced a tough moment.",
          "balanced_thought": "I can prepare and ask for support.",
          "suggestions": ["Take a short walk", "Write a quick plan"],
          "validation": "It makes sense to feel stressed."
        }
        """

        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(AIReframeResult.self, from: data)

        XCTAssertEqual(result.reframeSummary, "You faced a tough moment.")
        XCTAssertEqual(result.balancedThought, "I can prepare and ask for support.")
        XCTAssertEqual(result.suggestions, ["Take a short walk", "Write a quick plan"])
        XCTAssertEqual(result.validation, "It makes sense to feel stressed.")
    }
}
