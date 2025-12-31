import Foundation

@MainActor
final class EntryDetailViewModel: ObservableObject {
    @Published var record: ThoughtRecord?
    @Published var isLoading: Bool = false
    @Published var hasLoaded: Bool = false

    private let repository: ThoughtRecordRepository
    private var loadedEntryId: String?

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
#if DEBUG
        print("INIT EntryDetailViewModel \(ObjectIdentifier(self))")
#endif
    }

    deinit {
#if DEBUG
        print("DEINIT EntryDetailViewModel \(ObjectIdentifier(self))")
#endif
    }

    func loadIfNeeded(id: String) async {
        guard !hasLoaded || loadedEntryId != id else { return }
        loadedEntryId = id
        await load(id: id)
    }

    func load(id: String) async {
        hasLoaded = true
#if DEBUG
        print("LOAD EntryDetailViewModel.load called")
#endif
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
