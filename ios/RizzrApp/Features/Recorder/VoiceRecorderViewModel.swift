import Foundation

@MainActor
final class VoiceRecorderViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case processing
        case ready(RecordingSession)
        case transcribing(RecordingSession)
        case generating(String)
        case complete([ReplySuggestion])
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastRecording: RecordingSession?

    private weak var recorderClient: AudioRecorderClient?
    private var apiClient: RizzrAPIClient?

    func configure(recorderClient: AudioRecorderClient, apiClient: RizzrAPIClient) {
        self.recorderClient = recorderClient
        self.apiClient = apiClient
    }

    func start() async {
        guard let recorderClient else { return }
        do {
            try await recorderClient.startRecording()
            lastRecording = nil
            state = .recording
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stop() async {
        guard let recorderClient else { return }
        do {
            state = .processing
            let recording = try await recorderClient.stopRecording()
            lastRecording = recording
            state = .ready(recording)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func importRecording(from fileURL: URL) async {
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let importedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("rizzr-import-\(UUID().uuidString)")
                .appendingPathExtension(fileURL.pathExtension.isEmpty ? "m4a" : fileURL.pathExtension)
            if FileManager.default.fileExists(atPath: importedURL.path) {
                try FileManager.default.removeItem(at: importedURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: importedURL)
            let recording = RecordingSession(url: importedURL, duration: 1.0, createdAt: Date())
            lastRecording = recording
            state = .ready(recording)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func generateReplies() async {
        guard let apiClient, let recording = lastRecording else { return }
        do {
            state = .transcribing(recording)
            let transcription = try await apiClient.transcribeRecording(at: recording.url)
            state = .generating(transcription.transcript)
            let generated = try await apiClient.generateReplies(GenerateRepliesRequest(transcript: transcription.transcript))
            state = .complete(generated.replies)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func generateReplies(from text: String) async {
        guard let apiClient else { return }
        let transcript = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return }
        do {
            state = .generating(transcript)
            let generated = try await apiClient.generateReplies(GenerateRepliesRequest(transcript: transcript))
            state = .complete(generated.replies)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func generateAudioPreview(for text: String) async throws -> URL {
        guard let apiClient else {
            throw NSError(domain: "Rizzr", code: -1, userInfo: [NSLocalizedDescriptionKey: "API client unavailable."])
        }
        return try await apiClient.generateAudioPreview(for: text)
    }

    func reset() {
        lastRecording = nil
        state = .idle
    }
}
