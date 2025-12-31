import Foundation

struct AIReframeService {
    private let clientProvider: () throws -> OpenAIClient

    init(clientProvider: @escaping () throws -> OpenAIClient = {
        guard let key = OpenAIClient.loadAPIKey() else {
            throw OpenAIClient.OpenAIError.missingAPIKey
        }
        return OpenAIClient(apiKey: key)
    }) {
        self.clientProvider = clientProvider
    }

    func generateReframe(for record: ThoughtRecord) async throws -> AIReframeResult {
        let client = try clientProvider()
        let systemMessage = systemPrompt
        let userMessage = buildUserMessage(for: record)
        let content = try await client.chatCompletion(systemMessage: systemMessage, userMessage: userMessage)
        return parseResult(from: content)
    }

    var systemPrompt: String {
        "You are a supportive CBT-style journaling assistant. Do not diagnose. Avoid medical claims. Keep tone kind, practical, and concise."
    }

    func buildUserMessage(for record: ThoughtRecord) -> String {
        let emotionsText = listOrPlaceholder(record.emotions.map { "\($0.label) (\($0.intensityBefore)%)" })
        let sensationsText = listOrPlaceholder(record.sensations)
        let thoughtsText = listOrPlaceholder(record.automaticThoughts.map { "\($0.text) (belief \($0.beliefBefore)%)" })
        let distortionsText = listOrPlaceholder(record.thinkingStyles ?? [])
        let adaptiveText = adaptiveResponsesText(record)
        let outcomesText = outcomesSummaryText(record)

        return """
Here is the full thought record. Use the details below even if some fields are empty.

Date/time: \(record.createdAt)
Situation: \(record.situationText.isEmpty ? "(none provided)" : record.situationText)
Emotions: \(emotionsText)
Physical sensations: \(sensationsText)
Automatic thoughts: \(thoughtsText)
Cognitive distortions: \(distortionsText)
Evidence for/against: \(adaptiveText.evidence)
Alternative responses / adaptive responses: \(adaptiveText.alternatives)
Outcome / reflection: \(outcomesText)

Please:
- Validate feelings (1 sentence)
- Reframe cognitive distortions if present
- Provide a balanced alternative thought
- Provide 2–4 actionable suggestions
Keep tone supportive, non-clinical, and concise.

Return STRICT JSON with this shape:
{
  "reframe_summary": "...",
  "balanced_thought": "...",
  "suggestions": ["...", "..."],
  "validation": "..."
}
"""
    }

    private func parseResult(from content: String) -> AIReframeResult {
        if let result = decodeJSON(from: content) {
            return result
        }
        if let trimmed = extractJSON(from: content),
           let result = decodeJSON(from: trimmed) {
            return result
        }
        return AIReframeResult.fallback(from: content)
    }

    private func decodeJSON(from content: String) -> AIReframeResult? {
        guard let data = content.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AIReframeResult.self, from: data)
    }

    private func extractJSON(from content: String) -> String? {
        guard let start = content.firstIndex(of: "{") else { return nil }
        guard let end = content.lastIndex(of: "}") else { return nil }
        return String(content[start...end])
    }

    private func listOrPlaceholder(_ items: [String]) -> String {
        let trimmed = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        return trimmed.isEmpty ? "(none provided)" : trimmed.joined(separator: "; ")
    }

    private func adaptiveResponsesText(_ record: ThoughtRecord) -> (evidence: String, alternatives: String) {
        guard !record.adaptiveResponses.isEmpty else {
            return ("(none provided)", "(none provided)")
        }

        let evidenceEntries = record.adaptiveResponses.map { entry in
            let thoughtId = entry.key
            let responses = entry.value
            let thoughtLabel = record.automaticThoughts.first { $0.id == thoughtId }?.text ?? "Thought"
            let evidence = responses.evidenceText.isEmpty ? "(none)" : responses.evidenceText
            return "\(thoughtLabel): \(evidence)"
        }

        let alternativeEntries = record.adaptiveResponses.map { entry in
            let thoughtId = entry.key
            let responses = entry.value
            let thoughtLabel = record.automaticThoughts.first { $0.id == thoughtId }?.text ?? "Thought"
            let alternative = responses.alternativeText.isEmpty ? "(none)" : responses.alternativeText
            let outcome = responses.outcomeText.isEmpty ? "(none)" : responses.outcomeText
            let friend = responses.friendText.isEmpty ? "(none)" : responses.friendText
            return "\(thoughtLabel): Alternative: \(alternative); Outcome: \(outcome); Friend response: \(friend)"
        }

        return (evidenceEntries.joined(separator: " | "), alternativeEntries.joined(separator: " | "))
    }

    private func outcomesSummaryText(_ record: ThoughtRecord) -> String {
        guard !record.outcomesByThought.isEmpty else {
            return "(none provided)"
        }

        let entries = record.outcomesByThought.map { entry in
            let thoughtId = entry.key
            let outcome = entry.value
            let thoughtLabel = record.automaticThoughts.first { $0.id == thoughtId }?.text ?? "Thought"
            let reflection = outcome.reflection.isEmpty ? "(none)" : outcome.reflection
            return "\(thoughtLabel): belief after \(outcome.beliefAfter)%, reflection: \(reflection)"
        }

        return entries.joined(separator: " | ")
    }
}
