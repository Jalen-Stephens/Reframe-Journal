import Foundation
import OSLog

struct OpenAIClient {
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
