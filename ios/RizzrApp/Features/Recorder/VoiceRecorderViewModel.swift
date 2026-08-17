import Foundation

@MainActor
final class VoiceRecorderViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case ready(RecordingSession)
        case processing
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastRecording: RecordingSession?

    private weak var recorderClient: AudioRecorderClient?

    func configure(recorderClient: AudioRecorderClient) {
        self.recorderClient = recorderClient
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

    func reset() {
        lastRecording = nil
        state = .idle
    }
}
