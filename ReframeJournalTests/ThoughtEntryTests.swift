import XCTest
@testable import ReframeJournal

final class ThoughtEntryTests: XCTestCase {
    
    // MARK: - Empty Entry Tests
    
    func testEmptyEntryCreation() {
        let now = Date()
        let entry = ThoughtEntry.empty(now: now)
        
        XCTAssertEqual(entry.occurredAt, now)
        XCTAssertEqual(entry.title, "")
        XCTAssertEqual(entry.situation, "")
        XCTAssertEqual(entry.sensations, "")
        XCTAssertEqual(entry.emotions.count, 1)
        XCTAssertEqual(entry.emotions.first?.name, "")
        XCTAssertEqual(entry.emotions.first?.intensity, 50)
        XCTAssertTrue(entry.automaticThoughts.isEmpty)
        XCTAssertTrue(entry.thinkingStyles.isEmpty)
        XCTAssertTrue(entry.adaptiveResponses.isEmpty)
        XCTAssertTrue(entry.outcomesByThought.isEmpty)
        XCTAssertNil(entry.beliefAfterMainThought)
        XCTAssertNil(entry.aiReframe)
        XCTAssertTrue(entry.recordId.hasPrefix("id_"))
    }
    
    func testEmptyEntryHasUniqueIds() {
        let entry1 = ThoughtEntry.empty()
        let entry2 = ThoughtEntry.empty()
        
        XCTAssertNotEqual(entry1.id, entry2.id)
        XCTAssertNotEqual(entry1.recordId, entry2.recordId)
    }
    
    // MARK: - ThoughtRecord Conversion Tests
    
    func testInitFromThoughtRecord() {
        let record = ThoughtRecord(
            id: "id_12345678-1234-1234-1234-123456789abc",
            title: "Test Title",
            createdAt: "2024-01-15T10:30:00.000Z",
            updatedAt: "2024-01-15T11:00:00.000Z",
            situationText: "Test situation",
            sensations: ["Tight chest", "Racing heart"],
            automaticThoughts: [AutomaticThought(id: "t1", text: "I'm failing", beliefBefore: 80)],
            emotions: [Emotion(id: "e1", label: "Anxious", intensityBefore: 70, intensityAfter: 40)],
            thinkingStyles: ["Catastrophizing"],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: 50,
            notes: "Test notes",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )
        
        let entry = ThoughtEntry(record: record)
        
        XCTAssertEqual(entry.recordId, record.id)
        XCTAssertEqual(entry.title, "Test Title")
        XCTAssertEqual(entry.situation, "Test situation")
        XCTAssertEqual(entry.sensations, "Tight chest\nRacing heart")
        XCTAssertEqual(entry.automaticThoughts.count, 1)
        XCTAssertEqual(entry.automaticThoughts.first?.text, "I'm failing")
        XCTAssertEqual(entry.emotions.count, 1)
        XCTAssertEqual(entry.emotions.first?.name, "Anxious")
        XCTAssertEqual(entry.emotions.first?.intensity, 70)
        XCTAssertEqual(entry.thinkingStyles, ["Catastrophizing"])
    }
    
    func testInitFromThoughtRecordWithEmptyTitle() {
        let record = ThoughtRecord(
            id: "id_test",
            title: nil,
            createdAt: "2024-01-15T10:30:00.000Z",
            updatedAt: "2024-01-15T10:30:00.000Z",
            situationText: "",
            sensations: [],
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
        
        let entry = ThoughtEntry(record: record)
        
        XCTAssertEqual(entry.title, "")
        XCTAssertTrue(entry.thinkingStyles.isEmpty)
    }
    
    // MARK: - Applying Entry to Record Tests
    
    func testApplyingToNilRecord() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test123",
            occurredAt: Date(),
            title: "My Entry",
            situation: "A stressful meeting",
            sensations: "Tight chest\nSweaty palms",
            emotions: [EmotionItem(id: UUID(), name: "Anxious", intensity: 75)],
            automaticThoughts: [AutomaticThought(id: "t1", text: "I'll mess up", beliefBefore: 85)],
            thinkingStyles: ["Fortune telling"],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        XCTAssertEqual(record.id, "id_test123")
        XCTAssertEqual(record.title, "My Entry")
        XCTAssertEqual(record.situationText, "A stressful meeting")
        XCTAssertEqual(record.sensations, ["Tight chest", "Sweaty palms"])
        XCTAssertEqual(record.emotions.count, 1)
        XCTAssertEqual(record.emotions.first?.label, "Anxious")
        XCTAssertEqual(record.emotions.first?.intensityBefore, 75)
    }
    
    func testApplyingFiltersEmptyEmotions() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(),
            title: "",
            situation: "Test",
            sensations: "",
            emotions: [
                EmotionItem(id: UUID(), name: "Happy", intensity: 50),
                EmotionItem(id: UUID(), name: "", intensity: 50),
                EmotionItem(id: UUID(), name: "   ", intensity: 50)
            ],
            automaticThoughts: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        XCTAssertEqual(record.emotions.count, 1)
        XCTAssertEqual(record.emotions.first?.label, "Happy")
    }
    
    func testApplyingTrimsTitle() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(),
            title: "  Trimmed Title  ",
            situation: "",
            sensations: "",
            emotions: [],
            automaticThoughts: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        XCTAssertEqual(record.title, "Trimmed Title")
    }
    
    func testApplyingEmptyTitleBecomesNil() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(),
            title: "   ",
            situation: "",
            sensations: "",
            emotions: [],
            automaticThoughts: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        XCTAssertNil(record.title)
    }
    
    func testApplyingClampsEmotionIntensity() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(),
            title: "",
            situation: "",
            sensations: "",
            emotions: [
                EmotionItem(id: UUID(), name: "TooHigh", intensity: 150),
                EmotionItem(id: UUID(), name: "TooLow", intensity: -20)
            ],
            automaticThoughts: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        let high = record.emotions.first { $0.label == "TooHigh" }
        let low = record.emotions.first { $0.label == "TooLow" }
        
        XCTAssertEqual(high?.intensityBefore, 100)
        XCTAssertEqual(low?.intensityBefore, 0)
    }
    
    // MARK: - Sensation Splitting Tests
    
    func testSensationSplittingByNewlines() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(),
            title: "",
            situation: "",
            sensations: "Tight chest\nRacing heart\nSweaty palms",
            emotions: [],
            automaticThoughts: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        XCTAssertEqual(record.sensations.count, 3)
        XCTAssertTrue(record.sensations.contains("Tight chest"))
        XCTAssertTrue(record.sensations.contains("Racing heart"))
        XCTAssertTrue(record.sensations.contains("Sweaty palms"))
    }
    
    func testSensationSplittingFiltersEmpty() {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(),
            title: "",
            situation: "",
            sensations: "Valid\n\n  \nAnother valid",
            emotions: [],
            automaticThoughts: [],
            thinkingStyles: [],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: nil,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let record = entry.applying(to: nil)
        
        XCTAssertEqual(record.sensations.count, 2)
        XCTAssertEqual(record.sensations[0], "Valid")
        XCTAssertEqual(record.sensations[1], "Another valid")
    }
    
    // MARK: - Codable Tests
    
    func testThoughtEntryEncodingDecoding() throws {
        let entry = ThoughtEntry(
            id: UUID(),
            recordId: "id_test",
            occurredAt: Date(timeIntervalSince1970: 1700000000),
            title: "Test",
            situation: "Situation",
            sensations: "Sensations",
            emotions: [EmotionItem(id: UUID(), name: "Happy", intensity: 80)],
            automaticThoughts: [AutomaticThought(id: "t1", text: "Thought", beliefBefore: 70)],
            thinkingStyles: ["Style1"],
            adaptiveResponses: [:],
            outcomesByThought: [:],
            beliefAfterMainThought: 60,
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil,
            createdAt: Date(timeIntervalSince1970: 1700000000),
            updatedAt: Date(timeIntervalSince1970: 1700000000)
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ThoughtEntry.self, from: data)
        
        XCTAssertEqual(decoded.recordId, entry.recordId)
        XCTAssertEqual(decoded.title, entry.title)
        XCTAssertEqual(decoded.situation, entry.situation)
        XCTAssertEqual(decoded.beliefAfterMainThought, 60)
    }
}
