import Foundation

@MainActor
final class AIReframeViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var result: AIReframeResult?
    @Published var error: String?

    private let entryId: String
    private let repository: ThoughtRecordRepository
    private let service: AIReframeService
    private var depth: AIReframeDepth

    private var isDraftSource = false

    init(entryId: String, repository: ThoughtRecordRepository, service: AIReframeService, depth: AIReframeDepth) {
        self.entryId = entryId
        self.repository = repository
        self.service = service
        self.depth = depth
    }

    func loadExisting() async {
        isLoading = true
        defer { isLoading = false }
        error = nil
        do {
            if let record = try await repository.fetch(id: entryId) {
                isDraftSource = false
                result = record.aiReframe
                if let storedDepth = record.aiReframeDepth {
                    depth = storedDepth
                }
                return
            }
            if let draft = try await repository.fetchDraft(), draft.id == entryId {
                isDraftSource = true
                result = draft.aiReframe
                if let storedDepth = draft.aiReframeDepth {
                    depth = storedDepth
                }
                return
            }
            result = nil
            error = ThoughtRecordRepository.RepositoryError.entryNotFound.localizedDescription
        } catch let err {
            result = nil
            error = err.localizedDescription
        }
    }

    func generateAndSave() async {
        await generateAndSave(replaceExisting: false)
    }

    func regenerateAndSave() async {
        await generateAndSave(replaceExisting: true)
    }

    private func generateAndSave(replaceExisting: Bool) async {
        guard !isLoading else { return }
        isLoading = true
        error = nil
        if replaceExisting {
            result = nil
        }
        do {
            let record = try await loadRecord()
            let generated = try await service.generateReframe(for: record, depth: depth)
            let createdAt = Date()
            if isDraftSource {
                var updated = record
                updated.aiReframe = generated
                updated.aiReframeCreatedAt = createdAt
                updated.aiReframeModel = service.modelName
                updated.aiReframePromptVersion = service.promptVersion
                updated.aiReframeDepth = depth
                updated.updatedAt = DateUtils.nowIso()
                try await repository.saveDraft(updated)
            } else {
                try await repository.upsertAIReframe(
                    entryId: record.id,
                    result: generated,
                    createdAt: createdAt,
                    model: service.modelName,
                    promptVersion: service.promptVersion,
                    depth: depth
                )
            }
            result = generated
        } catch let err {
            if let openAIError = err as? OpenAIClient.OpenAIError {
                switch openAIError {
                case .missingAPIKey:
                    self.error = "Missing OpenAI API key. Set OPENAI_API_KEY in build settings or scheme."
                default:
                    self.error = openAIError.localizedDescription
                }
            } else {
                self.error = err.localizedDescription
            }
        }
        isLoading = false
    }

    private func loadRecord() async throws -> ThoughtRecord {
        if let record = try await repository.fetch(id: entryId) {
            isDraftSource = false
            return record
        }
        if let draft = try await repository.fetchDraft(), draft.id == entryId {
            isDraftSource = true
            return draft
        }
        throw ThoughtRecordRepository.RepositoryError.entryNotFound
    }

    func updateDepth(_ depth: AIReframeDepth) {
        self.depth = depth
    }

    func currentDepth() -> AIReframeDepth {
        depth
    }
}
