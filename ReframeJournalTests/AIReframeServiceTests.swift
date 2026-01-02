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
            notes: "",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )

        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = service.buildUserMessage(for: record, depth: .deep)

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
          "validation": "It makes sense to feel stressed.",
          "what_might_be_happening": ["There is a lot on your plate."],
          "cognitive_distortions": [
            { "label": "mind reading", "why_it_fits": "You assumed their reaction.", "gentle_reframe": "You don't have all the data yet." }
          ],
          "balanced_thought": "I can prepare and ask for support.",
          "micro_action_plan": [
            { "title": "Today", "steps": ["Make a short list"] }
          ],
          "communication_script": {
            "text_message": "Hey, can we talk later?",
            "in_person": "I'd like to share what's on my mind."
          },
          "self_compassion": ["I'm doing my best with a lot right now."],
          "reality_check_questions": ["What evidence supports this?"],
          "one_small_experiment": {
            "hypothesis": "They will judge me.",
            "experiment": "Ask for quick feedback.",
            "what_to_observe": ["Their tone"]
          },
          "summary": "You slowed down and found a more grounded view."
        }
        """

        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(AIReframeResult.self, from: data)

        XCTAssertEqual(result.balancedThought, "I can prepare and ask for support.")
        XCTAssertEqual(result.validation, "It makes sense to feel stressed.")
        XCTAssertEqual(result.whatMightBeHappening?.first, "There is a lot on your plate.")
        XCTAssertEqual(result.cognitiveDistortions?.first?.label, "mind reading")
    }
}
