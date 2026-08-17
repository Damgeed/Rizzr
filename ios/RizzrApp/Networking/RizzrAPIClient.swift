import Foundation

struct APIConfiguration: Equatable {
    let baseURL: URL
    let timeout: TimeInterval

    static let production = APIConfiguration(
        baseURL: Bundle.main.rizzrAPIBaseURL ?? URL(string: "https://api.rizzr.com")!,
        timeout: 30
    )
    static let local = APIConfiguration(baseURL: URL(string: "http://localhost:8000")!, timeout: 30)
}

enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case statusCode(Int)
    case decodingFailed
    case emptyResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "The server returned an invalid response."
        case .statusCode(let code): "The request failed with status code \(code)."
        case .decodingFailed: "The response could not be decoded."
        case .emptyResponse: "The server returned an empty response."
        case .server(let message): message
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

    func transcribeRecording(at fileURL: URL) async throws -> TranscribeResponse {
        let audioData = try Data(contentsOf: fileURL)
        let boundary = "RizzrBoundary-\(UUID().uuidString)"
        var request = URLRequest(url: configuration.baseURL.appending(path: "/api/transcribe"))
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeout
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = multipartBody(data: audioData, fileName: fileURL.lastPathComponent, mimeType: "audio/mp4", boundary: boundary)
        return try await decodeEnvelope(request)
    }

    func generateReplies(_ requestBody: GenerateRepliesRequest) async throws -> GenerateRepliesResponse {
        var request = URLRequest(url: configuration.baseURL.appending(path: "/api/generate"))
        request.httpMethod = "POST"
        request.timeoutInterval = configuration.timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try encoder.encode(requestBody)
        return try await decodeEnvelope(request)
    }

    private func decodeEnvelope<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard !data.isEmpty else { throw APIError.emptyResponse }

        let envelope = try decoder.decode(APIEnvelope<Response>.self, from: data)
        guard 200..<300 ~= httpResponse.statusCode else {
            throw APIError.server(envelope.error?.message ?? "The request failed with status code \(httpResponse.statusCode).")
        }
        guard envelope.success, let payload = envelope.data else {
            throw APIError.server(envelope.error?.message ?? "The request failed.")
        }
        return payload
    }

    private func multipartBody(data: Data, fileName: String, mimeType: String, boundary: String) -> Data {
        var body = Data()
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(data)
        body.appendString("\r\n--\(boundary)--\r\n")
        return body
    }
}

private extension Bundle {
    var rizzrAPIBaseURL: URL? {
        guard let rawValue = object(forInfoDictionaryKey: "RizzrAPIBaseURL") as? String else { return nil }
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, !trimmedValue.contains("$(") else { return nil }
        return URL(string: trimmedValue)
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

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
