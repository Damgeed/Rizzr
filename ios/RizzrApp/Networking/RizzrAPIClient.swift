import Foundation

struct APIConfiguration: Equatable {
    let baseURL: URL

    static let production = APIConfiguration(baseURL: URL(string: "https://api.rizzr.com")!)
    static let local = APIConfiguration(baseURL: URL(string: "http://localhost:8000")!)
}

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case statusCode(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an invalid response."
        case .statusCode(let code): "The request failed with status code \(code)."
        case .decodingFailed: "The response could not be decoded."
        }
    }
}

final class RizzrAPIClient {
    private let configuration: APIConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(configuration: APIConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }

    func generateReplies(_ request: GenerateRepliesRequest) async throws -> GenerateRepliesResponse {
        try await post(path: "/api/generate", body: request)
    }

    private func post<Request: Encodable, Response: Decodable>(path: String, body: Request) async throws -> Response {
        var request = URLRequest(url: configuration.baseURL.appending(path: path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard 200..<300 ~= httpResponse.statusCode else { throw APIError.statusCode(httpResponse.statusCode) }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}

private extension URL {
    func appending(path: String) -> URL {
        if #available(iOS 16.0, *) {
            return appending(path: path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        }
        return appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
    }
}
