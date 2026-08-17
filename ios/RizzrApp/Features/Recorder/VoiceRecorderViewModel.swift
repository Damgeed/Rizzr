import Foundation

@MainActor
final class VoiceRecorderViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
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

    func reset() {
        lastRecording = nil
        state = .idle
    }
}
