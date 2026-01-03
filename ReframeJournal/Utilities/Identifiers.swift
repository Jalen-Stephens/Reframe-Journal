import Foundation

enum Identifiers {
    static func generateId() -> String {
        "id_\(UUID().uuidString)"
    }
}

struct NotesDraftStore {
    struct Draft: Equatable {
        let entryId: String
        let section: ThoughtEntryViewModel.Section
    }

    private static let entryIdKey = "notesDraft.entryId"
    private static let sectionKey = "notesDraft.section"

    static func save(entryId: String, section: ThoughtEntryViewModel.Section) {
        let defaults = UserDefaults.standard
        defaults.set(entryId, forKey: entryIdKey)
        defaults.set(section.rawValue, forKey: sectionKey)
    }

    static func load() -> Draft? {
        let defaults = UserDefaults.standard
        guard let entryId = defaults.string(forKey: entryIdKey) else { return nil }
        let raw = defaults.integer(forKey: sectionKey)
        guard let section = ThoughtEntryViewModel.Section(rawValue: raw) else { return nil }
        return Draft(entryId: entryId, section: section)
    }

    static func clear() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: entryIdKey)
        defaults.removeObject(forKey: sectionKey)
    }
}
