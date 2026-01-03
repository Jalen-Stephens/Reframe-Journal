import XCTest
@testable import ReframeJournal

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
