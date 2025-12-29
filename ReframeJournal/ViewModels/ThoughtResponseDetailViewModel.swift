import Foundation

@MainActor
final class ThoughtResponseDetailViewModel: ObservableObject {
    @Published var record: ThoughtRecord?
    @Published var isLoading: Bool = false

    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
    }

    func load(entryId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            record = try await repository.fetch(id: entryId)
        } catch {
            print("Load entry failed", error)
            record = nil
        }
    }
}
