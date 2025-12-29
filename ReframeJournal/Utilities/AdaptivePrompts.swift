import Foundation

enum AdaptivePrompts {
    struct Prompt: Identifiable, Hashable {
        let id: String
        let label: String
        let textKey: TextKey
        let beliefKey: BeliefKey
    }

    enum TextKey: String, Hashable {
        case evidenceText
        case alternativeText
        case outcomeText
        case friendText
    }

    enum BeliefKey: String, Hashable {
        case evidenceBelief
        case alternativeBelief
        case outcomeBelief
        case friendBelief
    }

    static let all: [Prompt] = [
        Prompt(
            id: "evidence",
            label: "What is the evidence that the thought is true? Not true?",
            textKey: .evidenceText,
            beliefKey: .evidenceBelief
        ),
        Prompt(
            id: "alternative",
            label: "Is there an alternative explanation?",
            textKey: .alternativeText,
            beliefKey: .alternativeBelief
        ),
        Prompt(
            id: "outcome",
            label: "What's the worst that could happen? What's the best that could happen? What's the most realistic outcome?",
            textKey: .outcomeText,
            beliefKey: .outcomeBelief
        ),
        Prompt(
            id: "friend",
            label: "If a friend were in this situation and had this thought, what would I tell him/her?",
            textKey: .friendText,
            beliefKey: .friendBelief
        )
    ]
}
