// File: Models/Thought.swift
import Foundation

struct Thought: Codable, Equatable, Identifiable {
    let id: UUID
    let createdAt: Date
    var text: String
    var reframeResponse: ReframeResponse?

    init(id: UUID = UUID(), createdAt: Date = Date(), text: String, reframeResponse: ReframeResponse? = nil) {
        self.id = id
        self.createdAt = createdAt
        self.text = text
        self.reframeResponse = reframeResponse
    }
}

@MainActor
final class ThoughtStore: ObservableObject {
    @Published private(set) var thoughts: [Thought] = []

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("thoughts.json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        Task { await load() }
    }

    func addThought(text: String) async -> Thought {
        let newThought = Thought(text: text)
        thoughts.insert(newThought, at: 0)
        await persist()
        return newThought
    }

    func updateReframe(thoughtId: UUID, response: ReframeResponse) async {
        guard let index = thoughts.firstIndex(where: { $0.id == thoughtId }) else { return }
        thoughts[index].reframeResponse = response
        await persist()
    }

    func thought(id: UUID) -> Thought? {
        thoughts.first { $0.id == id }
    }

    private func load() async {
        let url = fileURL
        let decoder = decoder
        let data = await Task.detached(priority: .utility) { () -> Data? in
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            return try? Data(contentsOf: url)
        }.value

        guard let data else { return }
        if let decoded = try? decoder.decode([Thought].self, from: data) {
            thoughts = decoded.sorted(by: { $0.createdAt > $1.createdAt })
        }
    }

    private func persist() async {
        let url = fileURL
        let encoder = encoder
        let snapshot = thoughts
        _ = await Task.detached(priority: .utility) { () -> Bool in
            guard let data = try? encoder.encode(snapshot) else { return false }
            do {
                try data.write(to: url, options: [.atomic])
                return true
            } catch {
                return false
            }
        }.value
    }
}
