import Foundation

@MainActor
final class EntryDetailViewModel: ObservableObject {
    @Published var record: ThoughtRecord?
    @Published var isLoading: Bool = false

    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
    }

    func load(id: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            record = try await repository.fetch(id: id)
        } catch {
            print("Load entry failed", error)
            record = nil
        }
    }
}
