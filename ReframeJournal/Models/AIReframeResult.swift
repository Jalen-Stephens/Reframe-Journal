import Foundation

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
}
