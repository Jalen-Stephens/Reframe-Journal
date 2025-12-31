import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var entries: [ThoughtRecord] = []
    @Published var hasDraft: Bool = false
    @Published var isLoading: Bool = false

    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let recent = try await repository.fetchRecent(limit: 20)
            entries = recent
        } catch {
            print("Load entries failed", error)
            entries = []
        }
        do {
            let draft = try await repository.fetchDraft()
            hasDraft = (draft != nil)
        } catch {
            print("Load draft flag failed", error)
            hasDraft = false
        }
    }

    func deleteEntry(id: String) async {
        do {
            try await repository.delete(id: id)
            entries.removeAll { $0.id == id }
        } catch {
            print("Delete entry failed", error)
        }
    }
}
