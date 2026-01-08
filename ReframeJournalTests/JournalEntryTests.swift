import XCTest
import SwiftData
@testable import ReframeJournal

final class JournalEntryTests: XCTestCase {
    
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: JournalEntry.self, configurations: config)
        // mainContext access will be on MainActor in test methods
        modelContext = modelContainer.mainContext
    }
    
    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testDefaultInitialization() async {
        let entry = JournalEntry()
        
        XCTAssertFalse(entry.recordId.isEmpty)
        XCTAssertTrue(entry.recordId.hasPrefix("id_"))
        XCTAssertNil(entry.title)
        XCTAssertEqual(entry.situationText, "")
        XCTAssertTrue(entry.sensations.isEmpty)
        XCTAssertTrue(entry.automaticThoughts.isEmpty)
        XCTAssertTrue(entry.emotions.isEmpty)
        XCTAssertNil(entry.thinkingStyles)
        XCTAssertTrue(entry.adaptiveResponses.isEmpty)
        XCTAssertTrue(entry.outcomesByThought.isEmpty)
        XCTAssertNil(entry.beliefAfterMainThought)
        XCTAssertNil(entry.notes)
        XCTAssertNil(entry.aiReframe)
        XCTAssertNil(entry.aiReframeCreatedAt)
        XCTAssertNil(entry.aiReframeModel)
        XCTAssertNil(entry.aiReframePromptVersion)
        XCTAssertNil(entry.aiReframeDepth)
        XCTAssertFalse(entry.isDraft)
    }
    
    @MainActor
    func testFullInitialization() async {
        let now = Date()
        let thoughts = [AutomaticThought(id: "t1", text: "Test thought", beliefBefore: 80)]
        let emotions = [Emotion(id: "e1", label: "Anxious", intensityBefore: 70, intensityAfter: nil)]
        
        let entry = JournalEntry(
            recordId: "id_test123",
            title: "Test Entry",
            createdAt: now,
            updatedAt: now,
            situationText: "Test situation",
            sensations: ["Tight chest"],
            automaticThoughts: thoughts,
            emotions: emotions,
            thinkingStyles: ["Catastrophizing"],
            beliefAfterMainThought: 50,
            notes: "Test notes",
            isDraft: true
        )
        
        XCTAssertEqual(entry.recordId, "id_test123")
        XCTAssertEqual(entry.title, "Test Entry")
        XCTAssertEqual(entry.situationText, "Test situation")
        XCTAssertEqual(entry.sensations, ["Tight chest"])
        XCTAssertEqual(entry.automaticThoughts.count, 1)
        XCTAssertEqual(entry.automaticThoughts.first?.text, "Test thought")
        XCTAssertEqual(entry.emotions.count, 1)
        XCTAssertEqual(entry.emotions.first?.label, "Anxious")
        XCTAssertEqual(entry.thinkingStyles, ["Catastrophizing"])
        XCTAssertEqual(entry.beliefAfterMainThought, 50)
        XCTAssertEqual(entry.notes, "Test notes")
        XCTAssertTrue(entry.isDraft)
    }
    
    // MARK: - Empty Factory Test
    
    @MainActor
    func testEmptyFactory() {
        let now = Date()
        let entry = JournalEntry.empty(now: now)
        
        XCTAssertNotNil(entry.recordId)
        XCTAssertTrue(entry.recordId.hasPrefix("id_"))
        XCTAssertEqual(entry.createdAt, now)
        XCTAssertEqual(entry.updatedAt, now)
        XCTAssertEqual(entry.situationText, "")
    }
    
    @MainActor
    func testEmptyFactoryWithCustomId() {
        let customId = "id_custom_123"
        let entry = JournalEntry.empty(id: customId)
        
        XCTAssertEqual(entry.recordId, customId)
    }
    
    // MARK: - ThoughtRecord Conversion Tests
    
    @MainActor
    func testInitFromThoughtRecord() {
        let record = ThoughtRecord(
            id: "id_test",
            title: "Record Title",
            createdAt: "2024-01-15T10:30:00.000Z",
            updatedAt: "2024-01-15T11:00:00.000Z",
            situationText: "Test situation",
            sensations: ["Headache"],
            automaticThoughts: [AutomaticThought(id: "t1", text: "Thought", beliefBefore: 75)],
            emotions: [Emotion(id: "e1", label: "Sad", intensityBefore: 60, intensityAfter: nil)],
            thinkingStyles: ["Mind reading"],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: 40,
            notes: "Notes",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let entry = JournalEntry(from: record)
        
        XCTAssertEqual(entry.recordId, "id_test")
        XCTAssertEqual(entry.title, "Record Title")
        XCTAssertEqual(entry.situationText, "Test situation")
        XCTAssertEqual(entry.sensations, ["Headache"])
        XCTAssertEqual(entry.automaticThoughts.count, 1)
        XCTAssertEqual(entry.emotions.count, 1)
        XCTAssertEqual(entry.thinkingStyles, ["Mind reading"])
        XCTAssertEqual(entry.beliefAfterMainThought, 40)
        XCTAssertEqual(entry.notes, "Notes")
        XCTAssertFalse(entry.isDraft)
    }
    
    @MainActor
    func testToThoughtRecord() {
        let entry = JournalEntry(
            recordId: "id_test",
            title: "Entry Title",
            situationText: "Situation",
            sensations: ["Sensation"],
            automaticThoughts: [AutomaticThought(id: "t1", text: "Thought", beliefBefore: 70)],
            emotions: [Emotion(id: "e1", label: "Happy", intensityBefore: 80, intensityAfter: nil)],
            thinkingStyles: ["Style"],
            beliefAfterMainThought: 30,
            notes: "Notes"
        )
        
        let record = entry.toThoughtRecord()
        
        XCTAssertEqual(record.id, "id_test")
        XCTAssertEqual(record.title, "Entry Title")
        XCTAssertEqual(record.situationText, "Situation")
        XCTAssertEqual(record.sensations, ["Sensation"])
        XCTAssertEqual(record.automaticThoughts.count, 1)
        XCTAssertEqual(record.emotions.count, 1)
        XCTAssertEqual(record.thinkingStyles, ["Style"])
        XCTAssertEqual(record.beliefAfterMainThought, 30)
        XCTAssertEqual(record.notes, "Notes")
    }
    
    @MainActor
    func testUpdateFromThoughtRecord() {
        let entry = JournalEntry(recordId: "id_test", situationText: "Original")
        
        let record = ThoughtRecord(
            id: "id_test",
            title: "Updated Title",
            createdAt: "2024-01-15T10:00:00.000Z",
            updatedAt: "2024-01-15T12:00:00.000Z",
            situationText: "Updated situation",
            sensations: ["New sensation"],
            automaticThoughts: [],
            emotions: [],
            thinkingStyles: nil,
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: 45,
            notes: "Updated notes",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        entry.update(from: record)
        
        XCTAssertEqual(entry.title, "Updated Title")
        XCTAssertEqual(entry.situationText, "Updated situation")
        XCTAssertEqual(entry.sensations, ["New sensation"])
        XCTAssertEqual(entry.beliefAfterMainThought, 45)
        XCTAssertEqual(entry.notes, "Updated notes")
    }
    
    // MARK: - Completion Status Tests
    
    @MainActor
    func testCompletionStatusDraft() {
        let entry = JournalEntry()
        
        XCTAssertEqual(entry.completionStatus, .draft)
    }
    
    @MainActor
    func testCompletionStatusCompleteWithAIReframe() {
        let aiReframe = AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: "Test",
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: "Summary",
            rawResponse: nil
        )
        
        let entry = JournalEntry(aiReframe: aiReframe)
        
        XCTAssertEqual(entry.completionStatus, .complete)
    }
    
    @MainActor
    func testCompletionStatusCompleteWithCompletedOutcome() {
        let outcome = ThoughtOutcome(beliefAfter: 30, emotionsAfter: [:], reflection: "Done", isComplete: true)
        let entry = JournalEntry(outcomesByThought: ["t1": outcome])
        
        XCTAssertEqual(entry.completionStatus, .complete)
    }
    
    @MainActor
    func testCompletionStatusDraftWithIncompleteOutcome() {
        let outcome = ThoughtOutcome(beliefAfter: 30, emotionsAfter: [:], reflection: "", isComplete: false)
        let entry = JournalEntry(outcomesByThought: ["t1": outcome])
        
        XCTAssertEqual(entry.completionStatus, .draft)
    }
    
    // MARK: - AI Reframe Depth Tests
    
    @MainActor
    func testAIReframeDepthGetterSetter() {
        let entry = JournalEntry()
        
        XCTAssertNil(entry.aiReframeDepth)
        
        entry.aiReframeDepth = .deep
        XCTAssertEqual(entry.aiReframeDepth, .deep)
        XCTAssertEqual(entry.aiReframeDepthRaw, "deep")
        
        entry.aiReframeDepth = .quick
        XCTAssertEqual(entry.aiReframeDepth, .quick)
        XCTAssertEqual(entry.aiReframeDepthRaw, "quick")
        
        entry.aiReframeDepth = nil
        XCTAssertNil(entry.aiReframeDepth)
        XCTAssertNil(entry.aiReframeDepthRaw)
    }
    
    // MARK: - Adaptive Responses Tests
    
    @MainActor
    func testAdaptiveResponsesGetterSetter() {
        let entry = JournalEntry()
        
        XCTAssertTrue(entry.adaptiveResponses.isEmpty)
        
        let response = AdaptiveResponsesForThought(
            evidenceText: "Evidence",
            evidenceBelief: 40,
            alternativeText: "Alternative",
            alternativeBelief: 50,
            outcomeText: "Outcome",
            outcomeBelief: 60,
            friendText: "Friend",
            friendBelief: 70
        )
        
        entry.adaptiveResponses = ["t1": response]
        
        XCTAssertEqual(entry.adaptiveResponses.count, 1)
        XCTAssertEqual(entry.adaptiveResponses["t1"]?.evidenceText, "Evidence")
    }
    
    // MARK: - Outcomes By Thought Tests
    
    @MainActor
    func testOutcomesByThoughtGetterSetter() {
        let entry = JournalEntry()
        
        XCTAssertTrue(entry.outcomesByThought.isEmpty)
        
        let outcome = ThoughtOutcome(
            beliefAfter: 25,
            emotionsAfter: ["e1": 30],
            reflection: "Reflection",
            isComplete: true
        )
        
        entry.outcomesByThought = ["t1": outcome]
        
        XCTAssertEqual(entry.outcomesByThought.count, 1)
        XCTAssertEqual(entry.outcomesByThought["t1"]?.beliefAfter, 25)
        XCTAssertTrue(entry.outcomesByThought["t1"]?.isComplete ?? false)
    }
}
