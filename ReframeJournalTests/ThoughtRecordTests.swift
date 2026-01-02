import XCTest
@testable import ReframeJournal

final class ThoughtRecordTests: XCTestCase {
    func testEncodingDecodingRoundTrip() throws {
        let record = ThoughtRecord(
            id: "id_123",
            title: "Work presentation",
            createdAt: "2024-01-01T12:00:00Z",
            updatedAt: "2024-01-01T12:30:00Z",
            situationText: "Presentation went poorly",
            sensations: ["Tight chest"],
            automaticThoughts: [AutomaticThought(id: "t1", text: "I ruined it", beliefBefore: 80)],
            emotions: [Emotion(id: "e1", label: "Anxious", intensityBefore: 70, intensityAfter: nil)],
            thinkingStyles: ["Catastrophizing"],
            adaptiveResponses: [
                "t1": AdaptiveResponsesForThought(
                    evidenceText: "Mixed feedback",
                    evidenceBelief: 40,
                    alternativeText: "I can improve",
                    alternativeBelief: 60,
                    outcomeText: "Not a disaster",
                    outcomeBelief: 50,
                    friendText: "Be kind",
                    friendBelief: 70
                )
            ],
            outcomesByThought: [
                "t1": ThoughtOutcome(
                    beliefAfter: 30,
                    emotionsAfter: ["e1": 40],
                    reflection: "Learned something",
                    isComplete: true
                )
            ],
            beliefAfterMainThought: 30,
            notes: "",
            aiReframe: nil,
            aiReframeCreatedAt: nil,
            aiReframeModel: nil,
            aiReframePromptVersion: nil,
            aiReframeDepth: nil
        )

        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(ThoughtRecord.self, from: data)

        XCTAssertEqual(decoded.id, record.id)
        XCTAssertEqual(decoded.situationText, record.situationText)
        XCTAssertEqual(decoded.automaticThoughts.first?.text, record.automaticThoughts.first?.text)
        XCTAssertEqual(decoded.emotions.first?.label, record.emotions.first?.label)
        XCTAssertEqual(decoded.outcomesByThought["t1"]?.beliefAfter, 30)
    }

    func testMetricsValidation() {
        XCTAssertTrue(Metrics.isRequiredTextValid("hello"))
        XCTAssertFalse(Metrics.isRequiredTextValid("   "))
        XCTAssertEqual(Metrics.clampPercent(-10), 0)
        XCTAssertEqual(Metrics.clampPercent(120), 100)
    }

    func testPersistenceReadWrite() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ThoughtRecordStore(baseURL: tempDir)
        let record = ThoughtRecord.empty(nowIso: "2024-01-01T00:00:00Z", id: "id_test")

        try await store.upsert(record)
        let fetched = try await store.fetch(id: "id_test")
        XCTAssertEqual(fetched?.id, "id_test")

        try await store.delete(id: "id_test")
        let deleted = try await store.fetch(id: "id_test")
        XCTAssertNil(deleted)
    }
}
