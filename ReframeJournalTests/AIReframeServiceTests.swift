import XCTest
@testable import ReframeJournal

final class AIReframeServiceTests: XCTestCase {
    
    // MARK: - Service Configuration Tests
    
    func testServiceModelName() {
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        XCTAssertEqual(service.modelName, "gpt-4o-mini")
    }
    
    func testServicePromptVersion() {
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        XCTAssertEqual(service.promptVersion, "v2")
    }
    
    func testSystemPromptContent() {
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let prompt = service.systemPrompt
        
        XCTAssertTrue(prompt.contains("CBT"))
        XCTAssertTrue(prompt.contains("diagnose"))
        XCTAssertTrue(prompt.contains("JSON"))
    }
    
    // MARK: - buildUserMessage Tests
    
    @MainActor
    func testBuildUserMessageIncludesCoreFields() async {
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
        let message = await service.buildUserMessage(for: record, depth: .deep)

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
    
    @MainActor
    func testBuildUserMessageWithEmptyRecord() async {
        let record = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_test")
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("Situation: (none provided)"))
        XCTAssertTrue(message.contains("Emotions: (none provided)"))
        XCTAssertTrue(message.contains("Physical sensations: (none provided)"))
        XCTAssertTrue(message.contains("Automatic thoughts: (none provided)"))
        XCTAssertTrue(message.contains("Depth: Quick"))
    }
    
    @MainActor
    func testBuildUserMessageWithQuickDepth() async {
        let record = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_test")
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("Depth: Quick"))
    }
    
    @MainActor
    func testBuildUserMessageWithDeepDepth() async {
        let record = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_test")
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .deep)
        
        XCTAssertTrue(message.contains("Depth: Deep"))
    }
    
    @MainActor
    func testBuildUserMessageWithMultipleEmotions() async {
        let record = ThoughtRecord(
            id: "r1",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: [],
            automaticThoughts: [],
            emotions: [
                Emotion(id: "e1", label: "Anxious", intensityBefore: 70, intensityAfter: nil),
                Emotion(id: "e2", label: "Sad", intensityBefore: 50, intensityAfter: nil)
            ],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("Anxious (70%)"))
        XCTAssertTrue(message.contains("Sad (50%)"))
    }
    
    @MainActor
    func testBuildUserMessageWithMultipleSensations() async {
        let record = ThoughtRecord(
            id: "r1",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: ["Tight chest", "Racing heart", "Sweaty palms"],
            automaticThoughts: [],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("Tight chest"))
        XCTAssertTrue(message.contains("Racing heart"))
        XCTAssertTrue(message.contains("Sweaty palms"))
    }
    
    @MainActor
    func testBuildUserMessageIncludesSchemaPrompt() async {
        let record = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_test")
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("STRICT JSON"))
    }
    
    // MARK: - Adaptive Responses Text Tests
    
    @MainActor
    func testBuildUserMessageWithAdaptiveResponses() async {
        let thought = AutomaticThought(id: "t1", text: "Test thought", beliefBefore: 75)
        let responses = AdaptiveResponsesForThought(
            evidenceText: "Some evidence",
            evidenceBelief: 40,
            alternativeText: "An alternative",
            alternativeBelief: 50,
            outcomeText: "Possible outcome",
            outcomeBelief: 60,
            friendText: "Friend advice",
            friendBelief: 70
        )
        
        let record = ThoughtRecord(
            id: "r1",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: [],
            automaticThoughts: [thought],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [thought.id: responses],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("Some evidence"))
        XCTAssertTrue(message.contains("An alternative"))
        XCTAssertTrue(message.contains("Friend advice"))
    }
    
    @MainActor
    func testBuildUserMessageWithEmptyAdaptiveResponseFields() async {
        let thought = AutomaticThought(id: "t1", text: "Test thought", beliefBefore: 75)
        let responses = AdaptiveResponsesForThought(
            evidenceText: "",
            evidenceBelief: 0,
            alternativeText: "",
            alternativeBelief: 0,
            outcomeText: "",
            outcomeBelief: 0,
            friendText: "",
            friendBelief: 0
        )
        
        let record = ThoughtRecord(
            id: "r1",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: [],
            automaticThoughts: [thought],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [thought.id: responses],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("(none)"))
    }
    
    // MARK: - Outcomes Text Tests
    
    @MainActor
    func testBuildUserMessageWithOutcomes() async {
        let thought = AutomaticThought(id: "t1", text: "Negative thought", beliefBefore: 80)
        let outcome = ThoughtOutcome(
            beliefAfter: 40,
            emotionsAfter: [:],
            reflection: "I feel better now",
            isComplete: true
        )
        
        let record = ThoughtRecord(
            id: "r1",
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: [],
            automaticThoughts: [thought],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: [thought.id: outcome],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let service = AIReframeService(clientProvider: { throw LegacyOpenAIClient.OpenAIError.missingAPIKey })
        let message = await service.buildUserMessage(for: record, depth: .quick)
        
        XCTAssertTrue(message.contains("belief after 40%"))
        XCTAssertTrue(message.contains("I feel better now"))
    }

    // MARK: - AIReframeResult Decoding Tests
    
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
    
    func testAIReframeResultDecodesPartialJSON() throws {
        let json = """
        {
          "balanced_thought": "A simple thought",
          "summary": "Brief summary"
        }
        """
        
        let data = Data(json.utf8)
        let result = try JSONDecoder().decode(AIReframeResult.self, from: data)
        
        XCTAssertEqual(result.balancedThought, "A simple thought")
        XCTAssertEqual(result.summary, "Brief summary")
        XCTAssertNil(result.validation)
        XCTAssertNil(result.cognitiveDistortions)
    }
}
