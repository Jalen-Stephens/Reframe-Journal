import Foundation

struct StringOrStringArray: Codable, Equatable, Hashable {
    let string: String?
    let array: [String]?

    init(string: String) {
        self.string = string
        self.array = nil
    }

    init(array: [String]) {
        self.string = nil
        self.array = array
    }

    var asList: [String] {
        if let array {
            return array
        }
        if let string {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return [] }
            return AIReframeResult.splitLines(trimmed)
        }
        return []
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let list = try? container.decode([String].self) {
            self = StringOrStringArray(array: list)
            return
        }
        if let text = try? container.decode(String.self) {
            self = StringOrStringArray(string: text)
            return
        }
        throw DecodingError.typeMismatch(StringOrStringArray.self, DecodingError.Context(
            codingPath: decoder.codingPath,
            debugDescription: "Expected String or [String]."
        ))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let array {
            try container.encode(array)
        } else if let string {
            try container.encode(string)
        }
    }
}

struct AIReframeResult: Codable, Equatable, Hashable {
    struct CognitiveDistortion: Codable, Equatable, Hashable {
        let label: String
        let whyItFits: String
        let gentleReframe: String

        enum CodingKeys: String, CodingKey {
            case label
            case whyItFits = "why_it_fits"
            case gentleReframe = "gentle_reframe"
        }
    }

    struct MicroActionPlanItem: Codable, Equatable, Hashable {
        let title: String
        let steps: [String]

        enum CodingKeys: String, CodingKey {
            case title
            case steps
        }

        init(title: String, steps: [String]) {
            self.title = title
            self.steps = steps
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            title = (try? container.decode(String.self, forKey: .title)) ?? "Plan"
            if let helper = try? container.decode(StringOrStringArray.self, forKey: .steps) {
                steps = helper.asList
            } else {
                steps = []
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(title, forKey: .title)
            try container.encode(steps, forKey: .steps)
        }
    }

    struct CommunicationScript: Codable, Equatable, Hashable {
        let textMessage: String?
        let inPerson: String?

        enum CodingKeys: String, CodingKey {
            case textMessage = "text_message"
            case inPerson = "in_person"
        }
    }

    struct OneSmallExperiment: Codable, Equatable, Hashable {
        let hypothesis: String?
        let experiment: String?
        let whatToObserve: [String]?

        enum CodingKeys: String, CodingKey {
            case hypothesis
            case experiment
            case whatToObserve = "what_to_observe"
        }

        init(hypothesis: String?, experiment: String?, whatToObserve: [String]?) {
            self.hypothesis = hypothesis
            self.experiment = experiment
            self.whatToObserve = whatToObserve
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            hypothesis = try? container.decodeIfPresent(String.self, forKey: .hypothesis)
            experiment = try? container.decodeIfPresent(String.self, forKey: .experiment)
            if let helper = try? container.decodeIfPresent(StringOrStringArray.self, forKey: .whatToObserve) {
                let list = helper.asList
                whatToObserve = list.isEmpty ? nil : list
            } else {
                whatToObserve = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(hypothesis, forKey: .hypothesis)
            try container.encodeIfPresent(experiment, forKey: .experiment)
            try container.encodeIfPresent(whatToObserve, forKey: .whatToObserve)
        }
    }

    let validation: String?
    let whatMightBeHappening: [String]?
    let cognitiveDistortions: [CognitiveDistortion]?
    let balancedThought: String?
    let microActionPlan: [MicroActionPlanItem]?
    let communicationScript: CommunicationScript?
    let selfCompassion: [String]?
    let realityCheckQuestions: [String]?
    let oneSmallExperiment: OneSmallExperiment?
    let summary: String?
    let rawResponse: String?

    static let schemaForcingPrompt = """
Return STRICT JSON only. Arrays must be arrays, even if one item:
- what_might_be_happening: array of strings
- self_compassion: array of strings
- reality_check_questions: array of strings
- micro_action_plan.steps: array of strings
- one_small_experiment.what_to_observe: array of strings
No placeholders like "(item)".
"""

    static func fallback(from rawText: String) -> AIReframeResult {
        AIReframeResult(
            validation: nil,
            whatMightBeHappening: nil,
            cognitiveDistortions: nil,
            balancedThought: nil,
            microActionPlan: nil,
            communicationScript: nil,
            selfCompassion: nil,
            realityCheckQuestions: nil,
            oneSmallExperiment: nil,
            summary: nil,
            rawResponse: rawText
        )
    }

    var isFallbackOnly: Bool {
        summary == nil &&
        balancedThought == nil &&
        (whatMightBeHappening?.isEmpty ?? true) &&
        (cognitiveDistortions?.isEmpty ?? true) &&
        (microActionPlan?.isEmpty ?? true) &&
        (selfCompassion?.isEmpty ?? true) &&
        (realityCheckQuestions?.isEmpty ?? true) &&
        (rawResponse?.isEmpty == false)
    }

    enum CodingKeys: String, CodingKey {
        case validation
        case whatMightBeHappening = "what_might_be_happening"
        case cognitiveDistortions = "cognitive_distortions"
        case balancedThought = "balanced_thought"
        case microActionPlan = "micro_action_plan"
        case communicationScript = "communication_script"
        case selfCompassion = "self_compassion"
        case realityCheckQuestions = "reality_check_questions"
        case oneSmallExperiment = "one_small_experiment"
        case summary
        case rawResponse = "raw_response"
    }

    init(
        validation: String?,
        whatMightBeHappening: [String]?,
        cognitiveDistortions: [CognitiveDistortion]?,
        balancedThought: String?,
        microActionPlan: [MicroActionPlanItem]?,
        communicationScript: CommunicationScript?,
        selfCompassion: [String]?,
        realityCheckQuestions: [String]?,
        oneSmallExperiment: OneSmallExperiment?,
        summary: String?,
        rawResponse: String?
    ) {
        self.validation = validation
        self.whatMightBeHappening = whatMightBeHappening
        self.cognitiveDistortions = cognitiveDistortions
        self.balancedThought = balancedThought
        self.microActionPlan = microActionPlan
        self.communicationScript = communicationScript
        self.selfCompassion = selfCompassion
        self.realityCheckQuestions = realityCheckQuestions
        self.oneSmallExperiment = oneSmallExperiment
        self.summary = summary
        self.rawResponse = rawResponse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        validation = try container.decodeIfPresent(String.self, forKey: .validation)
        balancedThought = try container.decodeIfPresent(String.self, forKey: .balancedThought)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
        rawResponse = try container.decodeIfPresent(String.self, forKey: .rawResponse)

        whatMightBeHappening = Self.decodeList(from: container, key: .whatMightBeHappening)
        selfCompassion = Self.decodeList(from: container, key: .selfCompassion)
        realityCheckQuestions = Self.decodeList(from: container, key: .realityCheckQuestions)

        cognitiveDistortions = try container.decodeIfPresent([CognitiveDistortion].self, forKey: .cognitiveDistortions)
        microActionPlan = try container.decodeIfPresent([MicroActionPlanItem].self, forKey: .microActionPlan)
        communicationScript = try container.decodeIfPresent(CommunicationScript.self, forKey: .communicationScript)
        oneSmallExperiment = try container.decodeIfPresent(OneSmallExperiment.self, forKey: .oneSmallExperiment)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(validation, forKey: .validation)
        try container.encodeIfPresent(whatMightBeHappening, forKey: .whatMightBeHappening)
        try container.encodeIfPresent(cognitiveDistortions, forKey: .cognitiveDistortions)
        try container.encodeIfPresent(balancedThought, forKey: .balancedThought)
        try container.encodeIfPresent(microActionPlan, forKey: .microActionPlan)
        try container.encodeIfPresent(communicationScript, forKey: .communicationScript)
        try container.encodeIfPresent(selfCompassion, forKey: .selfCompassion)
        try container.encodeIfPresent(realityCheckQuestions, forKey: .realityCheckQuestions)
        try container.encodeIfPresent(oneSmallExperiment, forKey: .oneSmallExperiment)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encodeIfPresent(rawResponse, forKey: .rawResponse)
    }

    static func decodeAIReframe(from rawText: String) -> AIReframeResult {
        let jsonText = extractJSONObject(from: rawText) ?? rawText
        let data = jsonText.data(using: .utf8)

        if let data {
            do {
                let decoded = try JSONDecoder().decode(AIReframeResult.self, from: data)
                let wrapped = AIReframeResult(
                    validation: decoded.validation,
                    whatMightBeHappening: decoded.whatMightBeHappening,
                    cognitiveDistortions: decoded.cognitiveDistortions,
                    balancedThought: decoded.balancedThought,
                    microActionPlan: decoded.microActionPlan,
                    communicationScript: decoded.communicationScript,
                    selfCompassion: decoded.selfCompassion,
                    realityCheckQuestions: decoded.realityCheckQuestions,
                    oneSmallExperiment: decoded.oneSmallExperiment,
                    summary: decoded.summary,
                    rawResponse: rawText
                )
                return normalizeFromRaw(wrapped)
            } catch {
#if DEBUG
                print("AIReframe decode failed", error)
#endif
            }
        }

        let fallback = AIReframeResult.fallback(from: rawText)
        return normalizeFromRaw(fallback)
    }

    static func normalizeFromRaw(_ result: AIReframeResult) -> AIReframeResult {
        guard let raw = result.rawResponse,
              let jsonText = extractJSONObject(from: raw),
              let data = jsonText.data(using: .utf8) else {
            return result
        }

        let partial = try? JSONDecoder().decode(AIReframePartial.self, from: data)
        let json = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]

        let resolvedWhat = normalizedList(primary: partial?.whatMightBeHappening?.asList, fallback: result.whatMightBeHappening, rawKey: "what_might_be_happening", json: json)
        let resolvedSelf = normalizedList(primary: partial?.selfCompassion?.asList, fallback: result.selfCompassion, rawKey: "self_compassion", json: json)
        let resolvedQuestions = normalizedList(primary: partial?.realityCheckQuestions?.asList, fallback: result.realityCheckQuestions, rawKey: "reality_check_questions", json: json)
        let resolvedPlans = normalizedPlans(primary: partial?.microActionPlan, fallback: result.microActionPlan, json: json)
        let resolvedObserve = normalizedNestedList(primary: partial?.oneSmallExperiment?.whatToObserve?.asList, fallback: result.oneSmallExperiment?.whatToObserve, rawKey: "one_small_experiment", fieldKey: "what_to_observe", json: json)

        let normalizedExperiment: OneSmallExperiment?
        if let existing = result.oneSmallExperiment {
            normalizedExperiment = OneSmallExperiment(
                hypothesis: existing.hypothesis,
                experiment: existing.experiment,
                whatToObserve: resolvedObserve ?? existing.whatToObserve
            )
        } else {
            normalizedExperiment = result.oneSmallExperiment
        }

        return AIReframeResult(
            validation: result.validation,
            whatMightBeHappening: resolvedWhat,
            cognitiveDistortions: result.cognitiveDistortions,
            balancedThought: result.balancedThought,
            microActionPlan: resolvedPlans,
            communicationScript: result.communicationScript,
            selfCompassion: resolvedSelf,
            realityCheckQuestions: resolvedQuestions,
            oneSmallExperiment: normalizedExperiment,
            summary: result.summary,
            rawResponse: result.rawResponse
        )
    }

    private static func decodeList(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> [String]? {
        if let helper = try? container.decodeIfPresent(StringOrStringArray.self, forKey: key) {
            let list = helper.asList
            return list.isEmpty ? nil : list
        }
        return nil
    }

    static func splitLines(_ text: String) -> [String] {
        if text.contains("\n") {
            return text
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "-•")) }
                .filter { !$0.isEmpty }
        }
        return [text]
    }

    private static func normalizeList(_ list: [String]?, rawKey: String, json: [String: Any]) -> [String]? {
        if let rawList = json[rawKey] as? [Any] {
            let values = rawList.compactMap { $0 as? String }
            let cleaned = values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { isValidListItem($0) }
            return cleaned.isEmpty ? list : cleaned
        }
        if let rawText = json[rawKey] as? String {
            let cleaned = splitLines(rawText)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { isValidListItem($0) }
            return cleaned.isEmpty ? list : cleaned
        }
        return list
    }

    private static func normalizeNestedList(_ list: [String]?, rawKey: String, fieldKey: String, json: [String: Any]) -> [String]? {
        guard let object = json[rawKey] as? [String: Any] else { return list }
        if let rawList = object[fieldKey] as? [Any] {
            let values = rawList.compactMap { $0 as? String }
            let cleaned = values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { isValidListItem($0) }
            return cleaned.isEmpty ? list : cleaned
        }
        if let rawText = object[fieldKey] as? String {
            let cleaned = splitLines(rawText)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { isValidListItem($0) }
            return cleaned.isEmpty ? list : cleaned
        }
        return list
    }

    private static func normalizeActionPlans(_ plans: [MicroActionPlanItem]?, json: [String: Any]) -> [MicroActionPlanItem]? {
        guard let rawPlans = json["micro_action_plan"] as? [Any] else { return plans }
        let mapped: [MicroActionPlanItem] = rawPlans.compactMap { entry in
            guard let dict = entry as? [String: Any] else { return nil }
            let title = dict["title"] as? String ?? "Plan"
            let rawSteps = (dict["steps"] as? [Any])?.compactMap { $0 as? String }
            let rawText = dict["steps"] as? String
            let values = rawSteps ?? (rawText.map { splitLines($0) } ?? [])
            let cleaned = values
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { isValidListItem($0) }
            return MicroActionPlanItem(title: title, steps: cleaned)
        }
        return mapped.isEmpty ? plans : mapped
    }

    private static func normalizedList(primary: [String]?, fallback: [String]?, rawKey: String, json: [String: Any]) -> [String]? {
        if let primary, primary.contains(where: { isValidListItem($0) }) {
            return primary
        }
        let normalized = normalizeList(fallback, rawKey: rawKey, json: json)
        if let normalized, normalized.contains(where: { isValidListItem($0) }) {
            return normalized
        }
        return fallback
    }

    private static func normalizedNestedList(primary: [String]?, fallback: [String]?, rawKey: String, fieldKey: String, json: [String: Any]) -> [String]? {
        if let primary, primary.contains(where: { isValidListItem($0) }) {
            return primary
        }
        let normalized = normalizeNestedList(fallback, rawKey: rawKey, fieldKey: fieldKey, json: json)
        if let normalized, normalized.contains(where: { isValidListItem($0) }) {
            return normalized
        }
        return fallback
    }

    private static func normalizedPlans(primary: [MicroActionPlanItem]?, fallback: [MicroActionPlanItem]?, json: [String: Any]) -> [MicroActionPlanItem]? {
        if let primary, primary.contains(where: { $0.steps.contains(where: { isValidListItem($0) }) }) {
            return primary
        }
        let normalized = normalizeActionPlans(fallback, json: json)
        if let normalized, normalized.contains(where: { $0.steps.contains(where: { isValidListItem($0) }) }) {
            return normalized
        }
        return fallback
    }

    private static func isValidListItem(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        let scrubbed = trimmed
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "•", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = scrubbed.lowercased()
        return lowered != "item" && lowered != "..." && lowered != "…"
    }

    private static func extractJSONObject(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.first == "{" { return trimmed }
        guard let start = raw.firstIndex(of: "{"),
              let end = raw.lastIndex(of: "}") else {
            return nil
        }
        return String(raw[start...end])
    }
}

private struct AIReframePartial: Codable {
    let whatMightBeHappening: StringOrStringArray?
    let selfCompassion: StringOrStringArray?
    let realityCheckQuestions: StringOrStringArray?
    let microActionPlan: [AIReframeResult.MicroActionPlanItem]?
    let oneSmallExperiment: OneSmallExperimentPartial?

    enum CodingKeys: String, CodingKey {
        case whatMightBeHappening = "what_might_be_happening"
        case selfCompassion = "self_compassion"
        case realityCheckQuestions = "reality_check_questions"
        case microActionPlan = "micro_action_plan"
        case oneSmallExperiment = "one_small_experiment"
    }
}

private struct OneSmallExperimentPartial: Codable {
    let whatToObserve: StringOrStringArray?

    enum CodingKeys: String, CodingKey {
        case whatToObserve = "what_to_observe"
    }
}
