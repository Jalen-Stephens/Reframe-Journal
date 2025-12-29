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

    private let repository: ThoughtRecordRepository

    init(repository: ThoughtRecordRepository) {
        self.repository = repository
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await repository.fetchAll()
        } catch {
            print("Load all entries failed", error)
            entries = []
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
