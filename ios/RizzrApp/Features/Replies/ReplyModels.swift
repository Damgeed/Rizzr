import Foundation

struct ReplySuggestion: Identifiable, Codable, Equatable {
    enum Style: String, Codable, CaseIterable {
        case flirty
        case witty
        case sweet
    }

    let id: UUID
    let style: Style
    let text: String
    let audioPreviewURL: URL?

    init(id: UUID = UUID(), style: Style, text: String, audioPreviewURL: URL? = nil) {
        self.id = id
        self.style = style
        self.text = text
        self.audioPreviewURL = audioPreviewURL
    }
}

struct GenerateRepliesRequest: Encodable, Equatable {
    let transcript: String
    let styles: [ReplySuggestion.Style]
}

struct GenerateRepliesResponse: Decodable, Equatable {
    let replies: [ReplySuggestion]
}
