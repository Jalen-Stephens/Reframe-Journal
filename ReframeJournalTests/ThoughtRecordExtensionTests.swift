import XCTest
@testable import ReframeJournal

final class ThoughtRecordExtensionTests: XCTestCase {
    
    // MARK: - empty() Tests
    
    func testEmptyRecordCreation() {
        let now = "2024-01-15T10:30:00.000Z"
        let id = "id_test123"
        
        let record = ThoughtRecord.empty(nowIso: now, id: id)
        
        XCTAssertEqual(record.id, id)
        XCTAssertNil(record.title)
        XCTAssertEqual(record.createdAt, now)
        XCTAssertEqual(record.updatedAt, now)
        XCTAssertEqual(record.situationText, "")
        XCTAssertTrue(record.sensations.isEmpty)
        XCTAssertTrue(record.automaticThoughts.isEmpty)
        XCTAssertTrue(record.emotions.isEmpty)
        XCTAssertEqual(record.thinkingStyles, [])
        XCTAssertTrue(record.adaptiveResponses.isEmpty)
        XCTAssertTrue(record.outcomesByThought.isEmpty)
        XCTAssertNil(record.beliefAfterMainThought)
        XCTAssertEqual(record.notes, "")
        XCTAssertNil(record.aiReframe)
        XCTAssertNil(record.aiReframeCreatedAt)
        XCTAssertNil(record.aiReframeModel)
        XCTAssertNil(record.aiReframePromptVersion)
        XCTAssertNil(record.aiReframeDepth)
    }
    
    // MARK: - completionStatus Tests
    
    func testCompletionStatusDraftWhenEmpty() {
        let record = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_test")
        
        XCTAssertEqual(record.completionStatus, .draft)
    }
    
    func testCompletionStatusCompleteWithAIReframe() {
        let aiReframe = AIReframeResult(
            validation: "Valid",
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "Balanced",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: "Summary",
            rawResponse: nil
        )
        
        let record = ThoughtRecord(
            id: "id_test",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "",
            sensations: [],
            automaticThoughts: [],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: aiReframe,
            aiReframeCreatedAt: Date(),
            aiReframeModel: "gpt-4",
            aiReframePromptVersion: "v1",
            aiReframeDepth: .deep
        )
        
        XCTAssertEqual(record.completionStatus, .complete)
    }
    
    func testCompletionStatusCompleteWithCompletedOutcome() {
        let outcome = ThoughtOutcome(beliefAfter: 30, emotionsAfter: [:], reflection: "Done", isComplete: true)
        
        let record = ThoughtRecord(
            id: "id_test",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: [],
            automaticThoughts: [AutomaticThought(id: "t1", text: "Thought", beliefBefore: 80)],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: ["t1": outcome],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        XCTAssertEqual(record.completionStatus, .complete)
    }
    
    func testCompletionStatusDraftWithIncompleteOutcome() {
        let outcome = ThoughtOutcome(beliefAfter: 30, emotionsAfter: [:], reflection: "", isComplete: false)
        
        let record = ThoughtRecord(
            id: "id_test",
            title: nil,
            createdAt: "2024-01-01T00:00:00Z",
            updatedAt: "2024-01-01T00:00:00Z",
            situationText: "Test",
            sensations: [],
            automaticThoughts: [],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: ["t1": outcome],
            beliefAfterMainThought: nil,
            notes: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        XCTAssertEqual(record.completionStatus, .draft)
    }
    
    // MARK: - EntryCompletionStatus Tests
    
    func testEntryCompletionStatusIconComplete() {
        let status = EntryCompletionStatus.complete
        XCTAssertEqual(status.icon, .checkCircle)
    }
    
    func testEntryCompletionStatusIconDraft() {
        let status = EntryCompletionStatus.draft
        XCTAssertEqual(status.icon, .circle)
    }
    
    func testEntryCompletionStatusAccessibilityLabelComplete() {
        let status = EntryCompletionStatus.complete
        XCTAssertEqual(status.accessibilityLabel, "Completed entry")
    }
    
    func testEntryCompletionStatusAccessibilityLabelDraft() {
        let status = EntryCompletionStatus.draft
        XCTAssertEqual(status.accessibilityLabel, "Draft entry")
    }
    
    func testEntryCompletionStatusEquatable() {
        XCTAssertEqual(EntryCompletionStatus.complete, EntryCompletionStatus.complete)
        XCTAssertEqual(EntryCompletionStatus.draft, EntryCompletionStatus.draft)
        XCTAssertNotEqual(EntryCompletionStatus.complete, EntryCompletionStatus.draft)
    }
    
    // MARK: - Full ThoughtRecord Codable Tests
    
    func testThoughtRecordFullEncodingDecoding() throws {
        let record = ThoughtRecord(
            id: "id_full_test",
            title: "Full Test",
            createdAt: "2024-01-15T10:00:00.000Z",
            updatedAt: "2024-01-15T11:00:00.000Z",
            situationText: "A challenging situation",
            sensations: ["Tight chest", "Racing heart"],
            automaticThoughts: [
                AutomaticThought(id: "t1", text: "I'm failing", beliefBefore: 80),
                AutomaticThought(id: "t2", text: "Everyone will judge me", beliefBefore: 70)
            ],
            emotions: [
                Emotion(id: "e1", label: "Anxious", intensityBefore: 75, intensityAfter: 45),
                Emotion(id: "e2", label: "Frustrated", intensityBefore: 60, intensityAfter: nil)
            ],
            thinkingStyles: ["Catastrophizing", "Mind reading"],
            adaptiveResponses: [
                "t1": AdaptiveResponsesForThought(
                    evidenceText: "Evidence",
                    evidenceBelief: 40,
                    alternativeText: "Alternative",
                    alternativeBelief: 60,
                    outcomeText: "Outcome",
                    outcomeBelief: 50,
                    friendText: "Friend",
                    friendBelief: 70
                )
            ],
            outcomesByThought: [
                "t1": ThoughtOutcome(beliefAfter: 40, emotionsAfter: ["e1": 45], reflection: "Better", isComplete: true)
            ],
            beliefAfterMainThought: 45,
            notes: "Some notes",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(ThoughtRecord.self, from: data)
        
        XCTAssertEqual(decoded.id, record.id)
        XCTAssertEqual(decoded.title, record.title)
        XCTAssertEqual(decoded.situationText, record.situationText)
        XCTAssertEqual(decoded.sensations.count, 2)
        XCTAssertEqual(decoded.automaticThoughts.count, 2)
        XCTAssertEqual(decoded.emotions.count, 2)
        XCTAssertEqual(decoded.thinkingStyles?.count, 2)
        XCTAssertEqual(decoded.adaptiveResponses.count, 1)
        XCTAssertEqual(decoded.outcomesByThought.count, 1)
        XCTAssertEqual(decoded.beliefAfterMainThought, 45)
        XCTAssertEqual(decoded.notes, "Some notes")
    }
    
    func testThoughtRecordHashable() {
        let record1 = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_1")
        let record2 = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_1")
        let record3 = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_2")
        
        XCTAssertEqual(record1, record2)
        XCTAssertNotEqual(record1, record3)
    }
}
