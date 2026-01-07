import XCTest
@testable import ReframeJournal

final class AIReframeResultTests: XCTestCase {
    
    // MARK: - StringOrStringArray Tests
    
    func testStringOrStringArrayFromString() {
        let wrapper = StringOrStringArray(string: "single item")
        XCTAssertEqual(wrapper.string, "single item")
        XCTAssertNil(wrapper.array)
        XCTAssertEqual(wrapper.asList, ["single item"])
    }
    
    func testStringOrStringArrayFromArray() {
        let wrapper = StringOrStringArray(array: ["item1", "item2"])
        XCTAssertNil(wrapper.string)
        XCTAssertEqual(wrapper.array, ["item1", "item2"])
        XCTAssertEqual(wrapper.asList, ["item1", "item2"])
    }
    
    func testStringOrStringArrayAsListWithMultilineString() {
        let multiline = "line1\nline2\nline3"
        let wrapper = StringOrStringArray(string: multiline)
        let list = wrapper.asList
        
        XCTAssertEqual(list.count, 3)
        XCTAssertEqual(list[0], "line1")
        XCTAssertEqual(list[1], "line2")
        XCTAssertEqual(list[2], "line3")
    }
    
    func testStringOrStringArrayAsListWithEmptyString() {
        let wrapper = StringOrStringArray(string: "   ")
        XCTAssertTrue(wrapper.asList.isEmpty)
    }
    
    func testStringOrStringArrayDecodingFromArray() throws {
        let json = "[\"a\", \"b\", \"c\"]"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrStringArray.self, from: data)
        
        XCTAssertEqual(decoded.asList, ["a", "b", "c"])
    }
    
    func testStringOrStringArrayDecodingFromString() throws {
        let json = "\"single value\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(StringOrStringArray.self, from: data)
        
        XCTAssertEqual(decoded.asList, ["single value"])
    }
    
    func testStringOrStringArrayEncodingArray() throws {
        let wrapper = StringOrStringArray(array: ["x", "y"])
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("x"))
        XCTAssertTrue(json.contains("y"))
    }
    
    func testStringOrStringArrayEncodingString() throws {
        let wrapper = StringOrStringArray(string: "test")
        let data = try JSONEncoder().encode(wrapper)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertEqual(json, "\"test\"")
    }
    
    // MARK: - AIReframeResult Decoding Tests
    
    func testDecodeFullAIReframeResult() throws {
        let json = """
        {
          "validation": "It makes sense to feel stressed.",
          "what_might_be_happening": ["Possibility 1", "Possibility 2"],
          "cognitive_distortions": [
            {
              "label": "mind reading",
              "why_it_fits": "You assumed their reaction.",
              "gentle_reframe": "You don't have all the data yet."
            }
          ],
          "balanced_thought": "I can prepare and ask for support.",
          "micro_action_plan": [
            { "title": "Today", "steps": ["Step 1", "Step 2"] }
          ],
          "communication_script": {
            "text_message": "Hey, can we talk?",
            "in_person": "I'd like to share what's on my mind."
          },
          "self_compassion": ["Be kind to yourself."],
          "reality_check_questions": ["What evidence supports this?"],
          "one_small_experiment": {
            "hypothesis": "They will judge me.",
            "experiment": "Ask for feedback.",
            "what_to_observe": ["Their tone"]
          },
          "summary": "You found a more grounded view."
        }
        """
        
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AIReframeResult.self, from: data)
        
        XCTAssertEqual(result.validation, "It makes sense to feel stressed.")
        XCTAssertEqual(result.whatMightBeHappening, ["Possibility 1", "Possibility 2"])
        XCTAssertEqual(result.cognitiveDistortions?.count, 1)
        XCTAssertEqual(result.cognitiveDistortions?.first?.label, "mind reading")
        XCTAssertEqual(result.balancedThought, "I can prepare and ask for support.")
        XCTAssertEqual(result.microActionPlan?.count, 1)
        XCTAssertEqual(result.microActionPlan?.first?.title, "Today")
        XCTAssertEqual(result.microActionPlan?.first?.steps, ["Step 1", "Step 2"])
        XCTAssertEqual(result.communicationScript?.textMessage, "Hey, can we talk?")
        XCTAssertEqual(result.communicationScript?.inPerson, "I'd like to share what's on my mind.")
        XCTAssertEqual(result.selfCompassion, ["Be kind to yourself."])
        XCTAssertEqual(result.realityCheckQuestions, ["What evidence supports this?"])
        XCTAssertEqual(result.oneSmallExperiment?.hypothesis, "They will judge me.")
        XCTAssertEqual(result.oneSmallExperiment?.experiment, "Ask for feedback.")
        XCTAssertEqual(result.oneSmallExperiment?.whatToObserve, ["Their tone"])
        XCTAssertEqual(result.summary, "You found a more grounded view.")
    }
    
    func testDecodeMinimalAIReframeResult() throws {
        let json = "{}"
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AIReframeResult.self, from: data)
        
        XCTAssertNil(result.validation)
        XCTAssertNil(result.balancedThought)
        XCTAssertNil(result.summary)
    }
    
    func testDecodeAIReframeWithStringArrayFields() throws {
        let json = """
        {
          "what_might_be_happening": "Single line possibility",
          "self_compassion": "Single compassion statement",
          "reality_check_questions": "Single question"
        }
        """
        
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AIReframeResult.self, from: data)
        
        XCTAssertEqual(result.whatMightBeHappening, ["Single line possibility"])
        XCTAssertEqual(result.selfCompassion, ["Single compassion statement"])
        XCTAssertEqual(result.realityCheckQuestions, ["Single question"])
    }
    
    // MARK: - Fallback Tests
    
    func testFallbackFromRawText() {
        let rawText = "This is not JSON, just raw text from the AI."
        let result = AIReframeResult.fallback(from: rawText)
        
        XCTAssertNil(result.validation)
        XCTAssertNil(result.balancedThought)
        XCTAssertEqual(result.rawResponse, rawText)
    }
    
    func testIsFallbackOnly() {
        let fallback = AIReframeResult.fallback(from: "raw response text")
        XCTAssertTrue(fallback.isFallbackOnly)
        
        let proper = AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "A thought",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: nil,
            rawResponse: nil
        )
        XCTAssertFalse(proper.isFallbackOnly)
    }
    
    func testIsFallbackOnlyWithSummary() {
        let result = AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: nil,
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: "A summary",
            rawResponse: "raw"
        )
        XCTAssertFalse(result.isFallbackOnly)
    }
    
    // MARK: - decodeAIReframe Tests
    
    func testDecodeAIReframeFromValidJSON() {
        let json = """
        {
          "balanced_thought": "Test thought",
          "summary": "Test summary"
        }
        """
        
        let result = AIReframeResult.decodeAIReframe(from: json)
        
        XCTAssertEqual(result.balancedThought, "Test thought")
        XCTAssertEqual(result.summary, "Test summary")
        XCTAssertEqual(result.rawResponse, json)
    }
    
    func testDecodeAIReframeFromInvalidJSON() {
        let invalid = "This is not JSON"
        
        let result = AIReframeResult.decodeAIReframe(from: invalid)
        
        XCTAssertNil(result.balancedThought)
        XCTAssertEqual(result.rawResponse, invalid)
        XCTAssertTrue(result.isFallbackOnly)
    }
    
    func testDecodeAIReframeExtractsJSONFromText() {
        let textWithJSON = """
        Here's my analysis:
        {
          "balanced_thought": "Extracted thought"
        }
        Some trailing text.
        """
        
        let result = AIReframeResult.decodeAIReframe(from: textWithJSON)
        
        XCTAssertEqual(result.balancedThought, "Extracted thought")
    }
    
    // MARK: - splitLines Tests
    
    func testSplitLinesWithNewlines() {
        let text = "Line 1\nLine 2\nLine 3"
        let lines = AIReframeResult.splitLines(text)
        
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "Line 1")
        XCTAssertEqual(lines[1], "Line 2")
        XCTAssertEqual(lines[2], "Line 3")
    }
    
    func testSplitLinesSingleLine() {
        let text = "Single line without newlines"
        let lines = AIReframeResult.splitLines(text)
        
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0], text)
    }
    
    func testSplitLinesRemovesBullets() {
        let text = "- Item 1\n• Item 2\n  - Item 3"
        let lines = AIReframeResult.splitLines(text)
        
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "Item 1")
        XCTAssertEqual(lines[1], "Item 2")
        XCTAssertEqual(lines[2], "Item 3")
    }
    
    func testSplitLinesFiltersEmpty() {
        let text = "Line 1\n\n\nLine 2"
        let lines = AIReframeResult.splitLines(text)
        
        XCTAssertEqual(lines.count, 2)
    }
    
    // MARK: - Encoding Tests
    
    func testAIReframeResultEncodingRoundTrip() throws {
        let original = AIReframeResult(
            validation: "Valid",
            whatMightBeHappening: ["A", "B"],
            cognitiveDistortions: [
                AIReframeResult.CognitiveDistortion(label: "Label", whyItFits: "Why", gentleReframe: "Reframe")
            ],
            balancedThought: "Balanced",
            microActionPlan: [
                AIReframeResult.MicroActionPlanItem(title: "Plan", steps: ["Step"])
            ],
            communicationScript: AIReframeResult.CommunicationScript(textMessage: "Text", inPerson: "Person"),
            selfCompassion: ["Compassion"],
            realityCheckQuestions: ["Question"],
            oneSmallExperiment: AIReframeResult.OneSmallExperiment(hypothesis: "H", experiment: "E", whatToObserve: ["O"]),
            summary: "Summary",
            rawResponse: nil
        )
        
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AIReframeResult.self, from: data)
        
        XCTAssertEqual(decoded.validation, original.validation)
        XCTAssertEqual(decoded.balancedThought, original.balancedThought)
        XCTAssertEqual(decoded.summary, original.summary)
        XCTAssertEqual(decoded.whatMightBeHappening, original.whatMightBeHappening)
        XCTAssertEqual(decoded.selfCompassion, original.selfCompassion)
    }
    
    // MARK: - MicroActionPlanItem Tests
    
    func testMicroActionPlanItemDecoding() throws {
        let json = """
        {
          "title": "Today",
          "steps": ["Step 1", "Step 2"]
        }
        """
        
        let data = json.data(using: .utf8)!
        let item = try JSONDecoder().decode(AIReframeResult.MicroActionPlanItem.self, from: data)
        
        XCTAssertEqual(item.title, "Today")
        XCTAssertEqual(item.steps, ["Step 1", "Step 2"])
    }
    
    func testMicroActionPlanItemDecodingWithStringSteps() throws {
        let json = """
        {
          "title": "Plan",
          "steps": "Single step as string"
        }
        """
        
        let data = json.data(using: .utf8)!
        let item = try JSONDecoder().decode(AIReframeResult.MicroActionPlanItem.self, from: data)
        
        XCTAssertEqual(item.title, "Plan")
        XCTAssertEqual(item.steps, ["Single step as string"])
    }
    
    func testMicroActionPlanItemDecodingMissingTitle() throws {
        let json = """
        {
          "steps": ["Step"]
        }
        """
        
        let data = json.data(using: .utf8)!
        let item = try JSONDecoder().decode(AIReframeResult.MicroActionPlanItem.self, from: data)
        
        XCTAssertEqual(item.title, "Plan") // Default value
    }
    
    // MARK: - OneSmallExperiment Tests
    
    func testOneSmallExperimentDecoding() throws {
        let json = """
        {
          "hypothesis": "Test hypothesis",
          "experiment": "Test experiment",
          "what_to_observe": ["Observation 1", "Observation 2"]
        }
        """
        
        let data = json.data(using: .utf8)!
        let experiment = try JSONDecoder().decode(AIReframeResult.OneSmallExperiment.self, from: data)
        
        XCTAssertEqual(experiment.hypothesis, "Test hypothesis")
        XCTAssertEqual(experiment.experiment, "Test experiment")
        XCTAssertEqual(experiment.whatToObserve, ["Observation 1", "Observation 2"])
    }
    
    func testOneSmallExperimentDecodingWithStringObservations() throws {
        let json = """
        {
          "hypothesis": "H",
          "experiment": "E",
          "what_to_observe": "Single observation"
        }
        """
        
        let data = json.data(using: .utf8)!
        let experiment = try JSONDecoder().decode(AIReframeResult.OneSmallExperiment.self, from: data)
        
        XCTAssertEqual(experiment.whatToObserve, ["Single observation"])
    }
}
