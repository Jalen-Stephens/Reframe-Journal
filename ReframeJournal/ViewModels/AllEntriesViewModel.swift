import Foundation

struct EntrySection: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let entries: [ThoughtRecord]
}

@MainActor
final class AllEntriesViewModel: ObservableObject {
    @Published var entries: [ThoughtRecord] = []
    @Published var isLoading: Bool = false
    @Published var hasLoaded: Bool = false

    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
#if DEBUG
        print("INIT AllEntriesViewModel \(ObjectIdentifier(self))")
#endif
    }

    deinit {
#if DEBUG
        print("DEINIT AllEntriesViewModel \(ObjectIdentifier(self))")
#endif
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
    }

    func refresh() async {
        hasLoaded = true
#if DEBUG
        print("LOAD AllEntriesViewModel.refresh called")
#endif
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await repository.fetchAll()
        } catch {
            print("Load all entries failed", error)
            entries = []
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

    func sections() -> [EntrySection] {
        var today: [ThoughtRecord] = []
        var yesterday: [ThoughtRecord] = []
        var older: [ThoughtRecord] = []

        for entry in entries {
            let label = DateUtils.formatRelativeDate(entry.createdAt)
            if label == "Today" {
                today.append(entry)
            } else if label == "Yesterday" {
                yesterday.append(entry)
            } else {
                older.append(entry)
            }
        }

        var sections: [EntrySection] = []
        if !today.isEmpty { sections.append(EntrySection(title: "Today", entries: today)) }
        if !yesterday.isEmpty { sections.append(EntrySection(title: "Yesterday", entries: yesterday)) }
        if !older.isEmpty { sections.append(EntrySection(title: "Older", entries: older)) }
        return sections
    }
}
