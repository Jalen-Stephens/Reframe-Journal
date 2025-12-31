import Foundation

@MainActor
final class ThoughtResponseDetailViewModel: ObservableObject {
    @Published var record: ThoughtRecord?
    @Published var isLoading: Bool = false
    @Published var hasLoaded: Bool = false

    private let repository: ThoughtRecordRepository
    private var loadedEntryId: String?

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
#if DEBUG
        print("INIT ThoughtResponseDetailViewModel \(ObjectIdentifier(self))")
#endif
    }

    deinit {
#if DEBUG
        print("DEINIT ThoughtResponseDetailViewModel \(ObjectIdentifier(self))")
#endif
    }

    func loadIfNeeded(entryId: String) async {
        guard !hasLoaded || loadedEntryId != entryId else { return }
        loadedEntryId = entryId
        await load(entryId: entryId)
    }

    func load(entryId: String) async {
        hasLoaded = true
#if DEBUG
        print("LOAD ThoughtResponseDetailViewModel.load called")
#endif
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
