import Foundation

struct ReplySuggestion: Identifiable, Codable, Equatable {
    enum Style: String, Codable, CaseIterable {
        case flirty
        case witty
        case sweet
    }

    var id: String { "\(style.rawValue)-\(text)" }

    let style: Style
    let text: String
    let audioPreviewURL: URL?

    init(style: Style, text: String, audioPreviewURL: URL? = nil) {
        self.style = style
        self.text = text
        self.audioPreviewURL = audioPreviewURL
    }
}

struct TranscribeResponse: Decodable, Equatable {
    let transcript: String
    let language: String
    let duration: Double
}

struct GenerateRepliesRequest: Encodable, Equatable {
    let transcript: String
    let styles: [ReplySuggestion.Style]

    init(transcript: String, styles: [ReplySuggestion.Style] = ReplySuggestion.Style.allCases) {
        self.transcript = transcript
        self.styles = styles
    }
}

struct GenerateRepliesResponse: Decodable, Equatable {
    let replies: [ReplySuggestion]
}

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let error: APIErrorPayload?
}

struct APIErrorPayload: Decodable, Equatable {
    let code: String
    let message: String
}
