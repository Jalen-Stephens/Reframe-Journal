import Foundation

@MainActor
final class AIReframeViewModel: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var aiResult: AIReframeResult?
    @Published var aiError: String?

    private let service: AIReframeService

    init(service: AIReframeService) {
        self.service = service
    }

    func generateReframe(for record: ThoughtRecord) async {
        guard !isGenerating else { return }
        isGenerating = true
        aiError = nil
        do {
            let result = try await service.generateReframe(for: record)
            aiResult = result
        } catch {
            if let openAIError = error as? OpenAIClient.OpenAIError {
                switch openAIError {
                case .missingAPIKey:
                    aiError = "Missing OpenAI API key. Set OPENAI_API_KEY in build settings or scheme."
                default:
                    aiError = openAIError.localizedDescription
                }
            } else {
                aiError = error.localizedDescription
            }
        }
        isGenerating = false
    }

    func reset() {
        aiResult = nil
        aiError = nil
        isGenerating = false
    }
}
