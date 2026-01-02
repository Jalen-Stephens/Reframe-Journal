// File: Services/OpenAIClient.swift
import Foundation
import OSLog
import SwiftUI

protocol OpenAIClient {
    func generateReframe(for thought: Thought) async throws -> ReframeResponse
}

struct AnyOpenAIClient: OpenAIClient {
    private let generator: (Thought) async throws -> ReframeResponse

    init<C: OpenAIClient>(_ client: C) {
        self.generator = { thought in
            try await client.generateReframe(for: thought)
        }
    }

    func generateReframe(for thought: Thought) async throws -> ReframeResponse {
        try await generator(thought)
    }
}

struct BackendOpenAIClient: OpenAIClient {
    enum BackendError: LocalizedError {
        case invalidResponse
        case badStatus(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Unexpected response from server."
            case .badStatus(let status):
                return "Server request failed with status \(status)."
            }
        }
    }

    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }

    func generateReframe(for thought: Thought) async throws -> ReframeResponse {
        let url = baseURL.appendingPathComponent("reframe")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = ReframeRequest(thoughtId: thought.id, text: thought.text)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw BackendError.badStatus(httpResponse.statusCode)
        }
        return try JSONDecoder().decode(ReframeResponse.self, from: data)
    }

    static func loadBaseURL() -> URL? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: "BACKEND_BASE_URL") as? String else {
            return nil
        }
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("$(") else {
            return nil
        }
        return URL(string: trimmed)
    }
}

private struct ReframeRequest: Codable {
    let thoughtId: UUID
    let text: String
}

private struct OpenAIClientKey: EnvironmentKey {
    static let defaultValue = AnyOpenAIClient(UnavailableOpenAIClient())
}

extension EnvironmentValues {
    var openAIClient: AnyOpenAIClient {
        get { self[OpenAIClientKey.self] }
        set { self[OpenAIClientKey.self] = newValue }
    }
}

struct UnavailableOpenAIClient: OpenAIClient {
    func generateReframe(for thought: Thought) async throws -> ReframeResponse {
        throw UnavailableError()
    }

    struct UnavailableError: LocalizedError {
        var errorDescription: String? {
            "OpenAI client not configured."
        }
    }
}

// MARK: - Legacy Client (Deprecated)

struct LegacyOpenAIClient {
    enum OpenAIError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case badStatus(Int)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing OpenAI API key."
            case .invalidResponse:
                return "Unexpected response from OpenAI."
            case .badStatus(let status):
                return "OpenAI request failed with status \(status)."
            case .emptyResponse:
                return "OpenAI returned an empty response."
            }
        }
    }

    private let apiKey: String
    private let session: URLSession
    private let logger = Logger(subsystem: "ReframeJournal", category: "OpenAIClient")

    init(apiKey: String, timeout: TimeInterval = 30) {
        self.apiKey = apiKey
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }

    static func loadAPIKey() -> String? {
        let environmentKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        if let environmentKey, !environmentKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return environmentKey
        }

        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
            let trimmed = plistKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.hasPrefix("$(") {
                return trimmed
            }
        }

        return nil
    }

    func chatCompletion(systemMessage: String, userMessage: String, model: String) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ChatCompletionRequest(
            model: model,
            messages: [
                Message(role: "system", content: systemMessage),
                Message(role: "user", content: userMessage)
            ],
            temperature: 0.5,
            responseFormat: ResponseFormat(type: "json_object")
        )

        request.httpBody = try JSONEncoder().encode(payload)

        logger.debug("OpenAI request started")
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("OpenAI response missing HTTPURLResponse")
            throw OpenAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("OpenAI request failed with status \(httpResponse.statusCode)")
            throw OpenAIError.badStatus(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            logger.error("OpenAI response contained empty content")
            throw OpenAIError.emptyResponse
        }

        return content
    }
}

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }
}

private struct ResponseFormat: Codable {
    let type: String
}

private struct Message: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]
}

private struct Choice: Codable {
    let message: Message
}
