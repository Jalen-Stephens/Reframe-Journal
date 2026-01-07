import XCTest
@testable import ReframeJournal

final class AdaptivePromptsTests: XCTestCase {
    
    // MARK: - Prompt Structure Tests
    
    func testAllPromptsHasCorrectCount() {
        XCTAssertEqual(AdaptivePrompts.all.count, 4)
    }
    
    func testAllPromptsHaveUniqueIds() {
        let ids = AdaptivePrompts.all.map { $0.id }
        let uniqueIds = Set(ids)
        
        XCTAssertEqual(ids.count, uniqueIds.count)
    }
    
    func testAllPromptsHaveNonEmptyLabels() {
        for prompt in AdaptivePrompts.all {
            XCTAssertFalse(prompt.label.isEmpty, "Prompt \(prompt.id) should have a label")
        }
    }
    
    // MARK: - Individual Prompt Tests
    
    func testEvidencePrompt() {
        let evidence = AdaptivePrompts.all.first { $0.id == "evidence" }
        
        XCTAssertNotNil(evidence)
        XCTAssertEqual(evidence?.textKey, .evidenceText)
        XCTAssertEqual(evidence?.beliefKey, .evidenceBelief)
        XCTAssertTrue(evidence?.label.contains("evidence") ?? false)
    }
    
    func testAlternativePrompt() {
        let alternative = AdaptivePrompts.all.first { $0.id == "alternative" }
        
        XCTAssertNotNil(alternative)
        XCTAssertEqual(alternative?.textKey, .alternativeText)
        XCTAssertEqual(alternative?.beliefKey, .alternativeBelief)
        XCTAssertTrue(alternative?.label.contains("alternative") ?? false)
    }
    
    func testOutcomePrompt() {
        let outcome = AdaptivePrompts.all.first { $0.id == "outcome" }
        
        XCTAssertNotNil(outcome)
        XCTAssertEqual(outcome?.textKey, .outcomeText)
        XCTAssertEqual(outcome?.beliefKey, .outcomeBelief)
        XCTAssertTrue(outcome?.label.contains("worst") ?? false)
    }
    
    func testFriendPrompt() {
        let friend = AdaptivePrompts.all.first { $0.id == "friend" }
        
        XCTAssertNotNil(friend)
        XCTAssertEqual(friend?.textKey, .friendText)
        XCTAssertEqual(friend?.beliefKey, .friendBelief)
        XCTAssertTrue(friend?.label.contains("friend") ?? false)
    }
    
    // MARK: - TextKey Tests
    
    func testTextKeyRawValues() {
        XCTAssertEqual(AdaptivePrompts.TextKey.evidenceText.rawValue, "evidenceText")
        XCTAssertEqual(AdaptivePrompts.TextKey.alternativeText.rawValue, "alternativeText")
        XCTAssertEqual(AdaptivePrompts.TextKey.outcomeText.rawValue, "outcomeText")
        XCTAssertEqual(AdaptivePrompts.TextKey.friendText.rawValue, "friendText")
    }
    
    func testTextKeyHashable() {
        var set = Set<AdaptivePrompts.TextKey>()
        set.insert(.evidenceText)
        set.insert(.alternativeText)
        set.insert(.evidenceText) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - BeliefKey Tests
    
    func testBeliefKeyRawValues() {
        XCTAssertEqual(AdaptivePrompts.BeliefKey.evidenceBelief.rawValue, "evidenceBelief")
        XCTAssertEqual(AdaptivePrompts.BeliefKey.alternativeBelief.rawValue, "alternativeBelief")
        XCTAssertEqual(AdaptivePrompts.BeliefKey.outcomeBelief.rawValue, "outcomeBelief")
        XCTAssertEqual(AdaptivePrompts.BeliefKey.friendBelief.rawValue, "friendBelief")
    }
    
    func testBeliefKeyHashable() {
        var set = Set<AdaptivePrompts.BeliefKey>()
        set.insert(.evidenceBelief)
        set.insert(.outcomeBelief)
        set.insert(.evidenceBelief) // Duplicate
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - Prompt Hashable Tests
    
    func testPromptHashable() {
        let prompt1 = AdaptivePrompts.Prompt(id: "test", label: "Test", textKey: .evidenceText, beliefKey: .evidenceBelief)
        let prompt2 = AdaptivePrompts.Prompt(id: "test", label: "Test", textKey: .evidenceText, beliefKey: .evidenceBelief)
        let prompt3 = AdaptivePrompts.Prompt(id: "other", label: "Other", textKey: .alternativeText, beliefKey: .alternativeBelief)
        
        XCTAssertEqual(prompt1, prompt2)
        XCTAssertNotEqual(prompt1, prompt3)
        
        var set = Set<AdaptivePrompts.Prompt>()
        set.insert(prompt1)
        set.insert(prompt2) // Should not add duplicate
        set.insert(prompt3)
        
        XCTAssertEqual(set.count, 2)
    }
    
    // MARK: - Prompt Identifiable Tests
    
    func testPromptIdentifiable() {
        for prompt in AdaptivePrompts.all {
            XCTAssertEqual(prompt.id, prompt.id)
            XCTAssertFalse(prompt.id.isEmpty)
        }
    }
}
