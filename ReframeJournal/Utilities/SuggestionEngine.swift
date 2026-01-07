import Foundation

enum EmotionSuggestionEngine {
    static let defaultEmotions: [String] = [
        "anxious", "sad", "angry", "frustrated", "ashamed", "guilty", "embarrassed", "lonely",
        "overwhelmed", "stressed", "worried", "irritated", "hopeless", "discouraged", "insecure",
        "jealous", "betrayed", "hurt", "rejected", "confused", "tense", "exhausted", "numb", "fearful",
        "panicked", "uneasy", "drained", "unmotivated", "on edge"
    ]

    static func rankedSuggestions(
        situation: String,
        sensations: String,
        selected: [String],
        base: [String] = defaultEmotions,
        limit: Int? = nil
    ) -> [String] {
        let haystack = (situation + " " + sensations).lowercased()
        let selectedSet = Set(selected.map { $0.lowercased() })
        var scores: [String: Int] = [:]
        let normalizedBase = base.map { $0.lowercased() }
        normalizedBase.forEach { scores[$0] = 0 }

        for rule in emotionHeuristics {
            if rule.keywords.contains(where: { haystack.contains($0) }) {
                for emotion in rule.emotions {
                    scores[emotion, default: 0] += 2
                }
            }
        }

        let baseOrder = Dictionary(uniqueKeysWithValues: normalizedBase.enumerated().map { ($0.element, $0.offset) })
        let ordered = normalizedBase.sorted { lhs, rhs in
            let left = scores[lhs, default: 0]
            let right = scores[rhs, default: 0]
            if left != right {
                return left > right
            }
            return (baseOrder[lhs] ?? 0) < (baseOrder[rhs] ?? 0)
        }

        let filtered = ordered
            .filter { !selectedSet.contains($0) }
            .map { originalLabel(for: $0, base: base) }

        if let limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }

    private static func originalLabel(for value: String, base: [String]) -> String {
        base.first { $0.lowercased() == value } ?? value
    }

    private static let emotionHeuristics: [(keywords: [String], emotions: [String])] = [
        (["tight chest", "racing heart", "heart racing", "sweaty palms"], ["anxious", "panicked"]),
        (["nausea", "nauseous"], ["anxious", "uneasy"]),
        (["fatigue", "tired", "exhausted"], ["drained", "unmotivated", "overwhelmed"]),
        (["restless", "restlessness", "on edge"], ["on edge", "anxious"]),
        (["headache", "tense"], ["tense", "stressed"]),
        (["shame", "ashamed"], ["ashamed", "guilty", "embarrassed"]),
        (["rejected", "left out"], ["rejected", "lonely", "hurt"])
    ]
}

enum AutomaticThoughtSuggestionEngine {
    static func rankedSuggestions(
        situation: String,
        emotions: [String],
        limit: Int = 6
    ) -> [String] {
        let haystack = situation.lowercased()
        let emotionSet = Set(emotions.map { $0.lowercased() })
        var scored: [(String, Int)] = []
        for candidate in defaultThoughts {
            scored.append((candidate, 0))
        }

        func bump(_ thought: String, by value: Int) {
            if let index = scored.firstIndex(where: { $0.0 == thought }) {
                scored[index].1 += value
            }
        }

        if haystack.contains("presentation") || haystack.contains("meeting") || haystack.contains("interview") {
            bump("I'm going to mess this up.", by: 2)
            bump("They'll notice every mistake.", by: 2)
        }
        if haystack.contains("text") || haystack.contains("message") || haystack.contains("reply") {
            bump("They're ignoring me.", by: 2)
            bump("I did something wrong.", by: 1)
        }
        if emotionSet.contains("anxious") || emotionSet.contains("worried") || emotionSet.contains("stressed") {
            bump("Something bad is going to happen.", by: 2)
            bump("I can't handle this.", by: 2)
        }
        if emotionSet.contains("sad") || emotionSet.contains("hopeless") {
            bump("Nothing is going to get better.", by: 2)
            bump("I'm a burden.", by: 1)
        }
        if emotionSet.contains("angry") || emotionSet.contains("frustrated") {
            bump("This shouldn't be happening.", by: 2)
            bump("No one respects me.", by: 1)
        }

        let baseOrder = Dictionary(uniqueKeysWithValues: defaultThoughts.enumerated().map { ($0.element, $0.offset) })
        let ordered = scored.sorted { lhs, rhs in
            if lhs.1 != rhs.1 {
                return lhs.1 > rhs.1
            }
            return (baseOrder[lhs.0] ?? 0) < (baseOrder[rhs.0] ?? 0)
        }

        return Array(ordered.map { $0.0 }.prefix(limit))
    }

    private static let defaultThoughts: [String] = [
        "I'm going to mess this up.",
        "They'll notice every mistake.",
        "Something bad is going to happen.",
        "I can't handle this.",
        "I'm a burden.",
        "Nothing is going to get better.",
        "They're ignoring me.",
        "I did something wrong.",
        "This shouldn't be happening.",
        "No one respects me.",
        "I always fall short.",
        "I'm not good enough."
    ]
}
