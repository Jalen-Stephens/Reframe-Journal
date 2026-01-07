import XCTest
@testable import ReframeJournal

// MARK: - EmotionSuggestionEngine Tests

final class EmotionSuggestionEngineTests: XCTestCase {
    
    // MARK: - Default Emotions Tests
    
    func testDefaultEmotionsIsNotEmpty() {
        XCTAssertFalse(EmotionSuggestionEngine.defaultEmotions.isEmpty)
        XCTAssertGreaterThan(EmotionSuggestionEngine.defaultEmotions.count, 20)
    }
    
    func testDefaultEmotionsContainsCommonEmotions() {
        let defaults = EmotionSuggestionEngine.defaultEmotions
        
        XCTAssertTrue(defaults.contains("anxious"))
        XCTAssertTrue(defaults.contains("sad"))
        XCTAssertTrue(defaults.contains("angry"))
        XCTAssertTrue(defaults.contains("frustrated"))
        XCTAssertTrue(defaults.contains("overwhelmed"))
    }
    
    // MARK: - Ranked Suggestions Tests
    
    func testEmotionSuggestionsBoostAnxietyFromSensations() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "My chest felt tight and my heart was racing.",
            sensations: "Tight chest\nRacing heart",
            selected: []
        )
        XCTAssertTrue(suggestions.prefix(4).contains("anxious"))
        XCTAssertTrue(suggestions.prefix(6).contains("panicked"))
    }
    
    func testEmotionSuggestionsFilterSelectedEmotions() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "Test",
            sensations: "",
            selected: ["anxious", "sad"]
        )
        
        XCTAssertFalse(suggestions.contains("anxious"))
        XCTAssertFalse(suggestions.contains("sad"))
    }
    
    func testEmotionSuggestionsWithLimit() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "Test",
            sensations: "",
            selected: [],
            limit: 5
        )
        
        XCTAssertEqual(suggestions.count, 5)
    }
    
    func testEmotionSuggestionsWithNoLimit() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "Test",
            sensations: "",
            selected: [],
            limit: nil
        )
        
        XCTAssertEqual(suggestions.count, EmotionSuggestionEngine.defaultEmotions.count)
    }
    
    func testEmotionSuggestionsBoostNauseaRelatedEmotions() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "I feel nauseous",
            sensations: "Nausea",
            selected: []
        )
        
        XCTAssertTrue(suggestions.prefix(6).contains("anxious"))
        XCTAssertTrue(suggestions.prefix(6).contains("uneasy"))
    }
    
    func testEmotionSuggestionsBoostFatigueRelatedEmotions() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "I'm so tired and exhausted",
            sensations: "Fatigue",
            selected: []
        )
        
        XCTAssertTrue(suggestions.prefix(8).contains("drained"))
        XCTAssertTrue(suggestions.prefix(8).contains("overwhelmed"))
    }
    
    func testEmotionSuggestionsBoostShameRelatedEmotions() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "I feel ashamed of what I did",
            sensations: "",
            selected: []
        )
        
        XCTAssertTrue(suggestions.prefix(6).contains("ashamed"))
        XCTAssertTrue(suggestions.prefix(8).contains("guilty"))
    }
    
    func testEmotionSuggestionsBoostRejectionRelatedEmotions() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "I was rejected and left out",
            sensations: "",
            selected: []
        )
        
        XCTAssertTrue(suggestions.prefix(6).contains("rejected"))
        XCTAssertTrue(suggestions.prefix(8).contains("lonely"))
    }
    
    func testEmotionSuggestionsCaseInsensitiveFiltering() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "Test",
            sensations: "",
            selected: ["ANXIOUS", "Sad"]
        )
        
        XCTAssertFalse(suggestions.contains("anxious"))
        XCTAssertFalse(suggestions.contains("sad"))
    }
    
    func testEmotionSuggestionsWithCustomBase() {
        let customBase = ["happy", "excited", "joyful"]
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "Test",
            sensations: "",
            selected: [],
            base: customBase
        )
        
        XCTAssertEqual(suggestions.count, 3)
        XCTAssertTrue(suggestions.contains("happy"))
        XCTAssertTrue(suggestions.contains("excited"))
        XCTAssertTrue(suggestions.contains("joyful"))
    }
    
    func testEmotionSuggestionsPreserveOriginalCase() {
        let customBase = ["Happy", "EXCITED"]
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "Test",
            sensations: "",
            selected: [],
            base: customBase
        )
        
        XCTAssertTrue(suggestions.contains("Happy"))
        XCTAssertTrue(suggestions.contains("EXCITED"))
    }
    
    func testEmotionSuggestionsBoostTenseFromHeadache() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "I have a headache",
            sensations: "Tense muscles",
            selected: []
        )
        
        XCTAssertTrue(suggestions.prefix(6).contains("tense"))
        XCTAssertTrue(suggestions.prefix(8).contains("stressed"))
    }
    
    func testEmotionSuggestionsBoostOnEdge() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "I feel restless and on edge",
            sensations: "",
            selected: []
        )
        
        XCTAssertTrue(suggestions.prefix(6).contains("on edge"))
    }
}

// MARK: - AutomaticThoughtSuggestionEngine Tests

final class AutomaticThoughtSuggestionEngineTests: XCTestCase {
    
    func testAutomaticThoughtSuggestionsBoostPresentationScenario() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "I have a presentation at work tomorrow.",
            emotions: ["anxious"]
        )
        XCTAssertEqual(suggestions.first, "I'm going to mess this up.")
    }
    
    func testAutomaticThoughtSuggestionsDefaultLimit() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "Test",
            emotions: []
        )
        
        XCTAssertEqual(suggestions.count, 6)
    }
    
    func testAutomaticThoughtSuggestionsCustomLimit() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "Test",
            emotions: [],
            limit: 3
        )
        
        XCTAssertEqual(suggestions.count, 3)
    }
    
    func testAutomaticThoughtSuggestionsBoostMeetingScenario() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "Important meeting coming up",
            emotions: []
        )
        
        XCTAssertTrue(suggestions.prefix(3).contains("I'm going to mess this up."))
    }
    
    func testAutomaticThoughtSuggestionsBoostInterviewScenario() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "Job interview tomorrow",
            emotions: []
        )
        
        XCTAssertTrue(suggestions.prefix(3).contains("I'm going to mess this up."))
        XCTAssertTrue(suggestions.prefix(4).contains("They'll notice every mistake."))
    }
    
    func testAutomaticThoughtSuggestionsBoostTextMessageScenario() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "They haven't replied to my text",
            emotions: []
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("They're ignoring me."))
    }
    
    func testAutomaticThoughtSuggestionsBoostFromAnxiousEmotion() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["anxious"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("Something bad is going to happen."))
        XCTAssertTrue(suggestions.prefix(4).contains("I can't handle this."))
    }
    
    func testAutomaticThoughtSuggestionsBoostFromWorriedEmotion() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["worried"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("Something bad is going to happen."))
    }
    
    func testAutomaticThoughtSuggestionsBoostFromSadEmotion() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["sad"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("Nothing is going to get better."))
    }
    
    func testAutomaticThoughtSuggestionsBoostFromHopelessEmotion() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["hopeless"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("Nothing is going to get better."))
    }
    
    func testAutomaticThoughtSuggestionsBoostFromAngryEmotion() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["angry"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("This shouldn't be happening."))
    }
    
    func testAutomaticThoughtSuggestionsBoostFromFrustratedEmotion() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["frustrated"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("This shouldn't be happening."))
    }
    
    func testAutomaticThoughtSuggestionsMultipleEmotionBoosts() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: ["anxious", "sad", "angry"]
        )
        
        // Should have multiple boosted thoughts near the top
        XCTAssertTrue(suggestions.prefix(6).contains("Something bad is going to happen."))
        XCTAssertTrue(suggestions.prefix(6).contains("Nothing is going to get better."))
        XCTAssertTrue(suggestions.prefix(6).contains("This shouldn't be happening."))
    }
    
    func testAutomaticThoughtSuggestionsCaseInsensitiveEmotions() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General",
            emotions: ["ANXIOUS", "Sad"]
        )
        
        XCTAssertTrue(suggestions.prefix(4).contains("Something bad is going to happen."))
        XCTAssertTrue(suggestions.prefix(4).contains("Nothing is going to get better."))
    }
    
    func testAutomaticThoughtSuggestionsEmptyEmotions() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "General situation",
            emotions: []
        )
        
        // Should still return suggestions from the default list
        XCTAssertEqual(suggestions.count, 6)
        XCTAssertFalse(suggestions.isEmpty)
    }
    
    func testAutomaticThoughtSuggestionsEmptySituation() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "",
            emotions: ["anxious"]
        )
        
        // Should still boost based on emotions
        XCTAssertTrue(suggestions.prefix(4).contains("Something bad is going to happen."))
    }
}

// MARK: - Legacy Test Class for Compatibility

final class SuggestionEngineTests: XCTestCase {
    func testEmotionSuggestionsBoostAnxietyFromSensations() {
        let suggestions = EmotionSuggestionEngine.rankedSuggestions(
            situation: "My chest felt tight and my heart was racing.",
            sensations: "Tight chest\nRacing heart",
            selected: []
        )
        XCTAssertTrue(suggestions.prefix(4).contains("anxious"))
        XCTAssertTrue(suggestions.prefix(6).contains("panicked"))
    }

    func testAutomaticThoughtSuggestionsBoostPresentationScenario() {
        let suggestions = AutomaticThoughtSuggestionEngine.rankedSuggestions(
            situation: "I have a presentation at work tomorrow.",
            emotions: ["anxious"]
        )
        XCTAssertEqual(suggestions.first, "I'm going to mess this up.")
    }
}
