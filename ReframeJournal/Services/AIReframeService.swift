import Foundation

struct AIReframeService {
    private let clientProvider: () throws -> LegacyOpenAIClient
    private let valuesService: ValuesProfileService?
    let modelName = "gpt-4o-mini"
    let promptVersion = "v3"

    init(
        clientProvider: @escaping () throws -> LegacyOpenAIClient = {
            guard let key = LegacyOpenAIClient.loadAPIKey() else {
                throw LegacyOpenAIClient.OpenAIError.missingAPIKey
            }
            return LegacyOpenAIClient(apiKey: key)
        },
        valuesService: ValuesProfileService? = nil
    ) {
        self.clientProvider = clientProvider
        self.valuesService = valuesService
    }

    func generateReframe(for record: ThoughtRecord, depth: AIReframeDepth) async throws -> AIReframeResult {
        let client = try clientProvider()
        let systemMessage = systemPrompt
        let userMessage = await buildUserMessage(for: record, depth: depth)
        let content = try await client.chatCompletion(systemMessage: systemMessage, userMessage: userMessage, model: modelName)
        return AIReframeResult.decodeAIReframe(from: content)
    }

    var systemPrompt: String {
        "You are a supportive CBT-style journaling assistant. Do not diagnose. Do not provide medical advice. Be kind, practical, and specific. Return STRICT JSON only."
    }

    @MainActor
    func buildUserMessage(for record: ThoughtRecord, depth: AIReframeDepth) async -> String {
        let emotionsText = listOrPlaceholder(record.emotions.map { "\($0.label) (\($0.intensityBefore)%)" })
        let sensationsText = listOrPlaceholder(record.sensations)
        let thoughtsText = listOrPlaceholder(record.automaticThoughts.map { "\($0.text) (belief \($0.beliefBefore)%)" })
        let distortionsText = listOrPlaceholder(record.thinkingStyles ?? [])
        let adaptiveText = adaptiveResponsesText(record)
        let outcomesText = outcomesSummaryText(record)
        let valuesText = await valuesContextText(record)

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
\(valuesText)
Depth: \(depth.promptLabel)

Constraints:
- Keep tone supportive, non-judgmental, and non-clinical.
- Avoid generic filler; tie statements to the entry details.
- No diagnosis and no medical advice.
- Do not use placeholders like "(item)" or "..."; provide real, specific text.
- If values are provided, incorporate them naturally into the reframe and action plan. Do NOT be preachy or moralizing—keep it calm, personal, and user-led.
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
  "values_aligned_intention": "1–2 sentences connecting the reframe to the user's stated values (only if values provided, otherwise null)",
  "next_best_step": "1 concrete, values-aligned action the user can take (only if values provided, otherwise null)",
  "summary": "short wrap-up paragraph"
}
"""
    }
    
    @MainActor
    private func valuesContextText(_ record: ThoughtRecord) async -> String {
        guard let selected = record.selectedValues, selected.hasSelection else {
            return ""
        }
        
        var parts: [String] = []
        
        // Categories
        if !selected.categories.isEmpty {
            let categoryNames = selected.categories.map { $0.title }.joined(separator: ", ")
            parts.append("Values categories: \(categoryNames)")
            
            // Include snippets from profile if available
            if let service = valuesService {
                // Ensure service is loaded
                await service.load()
                for category in selected.categories {
                    let entry = service.entry(for: category)
                    if entry.hasContent {
                        var snippetParts: [String] = []
                        if !entry.whatMatters.isEmpty {
                            let trimmed = entry.whatMatters.trimmingCharacters(in: .whitespacesAndNewlines)
                            let snippet = trimmed.count > 150 ? String(trimmed.prefix(150)) + "…" : trimmed
                            snippetParts.append("What matters: \(snippet)")
                        }
                        if !entry.howToShowUp.isEmpty {
                            let trimmed = entry.howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines)
                            let snippet = trimmed.count > 100 ? String(trimmed.prefix(100)) + "…" : trimmed
                            snippetParts.append("How to show up: \(snippet)")
                        }
                        if !snippetParts.isEmpty {
                            parts.append("  \(category.title): \(snippetParts.joined(separator: "; "))")
                        }
                    }
                }
            }
        }
        
        // Keywords
        if !selected.keywords.isEmpty {
            parts.append("Value keywords: \(selected.keywords.joined(separator: ", "))")
        }
        
        // How to show up (situation-specific)
        let howToShowUp = selected.howToShowUp.trimmingCharacters(in: .whitespacesAndNewlines)
        if !howToShowUp.isEmpty {
            parts.append("How I want to show up here: \(howToShowUp)")
        }
        
        guard !parts.isEmpty else { return "" }
        return "\nUser's values context:\n" + parts.joined(separator: "\n") + "\n"
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
