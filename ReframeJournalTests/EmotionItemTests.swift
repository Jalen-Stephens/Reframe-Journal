import XCTest
@testable import ReframeJournal

final class EmotionItemTests: XCTestCase {
    
    func testEmotionItemCreation() {
        let id = UUID()
        let emotion = EmotionItem(id: id, name: "Anxious", intensity: 75)
        
        XCTAssertEqual(emotion.id, id)
        XCTAssertEqual(emotion.name, "Anxious")
        XCTAssertEqual(emotion.intensity, 75)
    }
    
    func testEmotionItemMutability() {
        var emotion = EmotionItem(id: UUID(), name: "Happy", intensity: 50)
        
        emotion.name = "Sad"
        emotion.intensity = 80
        
        XCTAssertEqual(emotion.name, "Sad")
        XCTAssertEqual(emotion.intensity, 80)
    }
    
    func testEmotionItemCodable() throws {
        let emotion = EmotionItem(id: UUID(), name: "Excited", intensity: 90)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(emotion)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(EmotionItem.self, from: data)
        
        XCTAssertEqual(decoded.id, emotion.id)
        XCTAssertEqual(decoded.name, "Excited")
        XCTAssertEqual(decoded.intensity, 90)
    }
    
    func testEmotionItemHashable() {
        let id = UUID()
        let emotion1 = EmotionItem(id: id, name: "Anxious", intensity: 75)
        let emotion2 = EmotionItem(id: id, name: "Anxious", intensity: 75)
        let emotion3 = EmotionItem(id: UUID(), name: "Anxious", intensity: 75)
        
        XCTAssertEqual(emotion1, emotion2)
        XCTAssertNotEqual(emotion1, emotion3)
        
        var set = Set<EmotionItem>()
        set.insert(emotion1)
        set.insert(emotion2)
        set.insert(emotion3)
        
        XCTAssertEqual(set.count, 2) // emotion1 and emotion2 are equal, so only 2 unique items
    }
    
    func testEmotionItemIdentifiable() {
        let id = UUID()
        let emotion = EmotionItem(id: id, name: "Happy", intensity: 60)
        
        XCTAssertEqual(emotion.id, id)
    }
}
