import Foundation

struct AIReframeService {
    private let clientProvider: () throws -> OpenAIClient
    let modelName = "gpt-4o-mini"
    let promptVersion = "v2"

    init(clientProvider: @escaping () throws -> OpenAIClient = {
        guard let key = OpenAIClient.loadAPIKey() else {
            throw OpenAIClient.OpenAIError.missingAPIKey
        }
        return OpenAIClient(apiKey: key)
    }) {
        self.clientProvider = clientProvider
    }

    func generateReframe(for record: ThoughtRecord, depth: AIReframeDepth) async throws -> AIReframeResult {
        let client = try clientProvider()
        let systemMessage = systemPrompt
        let userMessage = buildUserMessage(for: record, depth: depth)
        let content = try await client.chatCompletion(systemMessage: systemMessage, userMessage: userMessage, model: modelName)
        return AIReframeResult.decodeAIReframe(from: content)
    }

    var systemPrompt: String {
        "You are a supportive CBT-style journaling assistant. Do not diagnose. Do not provide medical advice. Be kind, practical, and specific. Return STRICT JSON only."
    }

    func buildUserMessage(for record: ThoughtRecord, depth: AIReframeDepth) -> String {
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

Depth: \(depth.promptLabel)

Constraints:
- Keep tone supportive, non-judgmental, and non-clinical.
- Avoid generic filler; tie statements to the entry details.
- No diagnosis and no medical advice.
- Do not use placeholders like "(item)" or "..."; provide real, specific text.
\(AIReframeResult.schemaForcingPrompt)

Please return STRICT JSON with this shape:
{
  "validation": "1–2 sentences validating feelings",
  "what_might_be_happening": ["3–6 alternative explanations"],
  "cognitive_distortions": [
    {
      "label": "e.g., mind reading",
      "why_it_fits": "1 sentence",
      "gentle_reframe": "1 sentence"
    }
  ],
  "balanced_thought": "2–4 sentences, specific and believable",
  "micro_action_plan": [
    { "title": "Right now (2 minutes)", "steps": ["...", "..."] },
    { "title": "Today", "steps": ["...", "..."] },
    { "title": "If it happens again", "steps": ["...", "..."] }
  ],
  "communication_script": {
    "text_message": "short supportive text message",
    "in_person": "short in-person script"
  },
  "self_compassion": ["2–4 sentences"],
  "reality_check_questions": ["5–8 questions"],
  "one_small_experiment": {
    "hypothesis": "what the user fears",
    "experiment": "one small test they can try",
    "what_to_observe": ["...", "..."]
  },
  "summary": "short wrap-up paragraph"
}
"""
    }

    private func parseResult(from content: String) -> AIReframeResult {
        AIReframeResult.decodeAIReframe(from: content)
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
