import Foundation

@MainActor
final class VoiceRecorderViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case processing
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var lastRecordingURL: URL?

    private weak var recorderClient: AudioRecorderClient?

    func configure(recorderClient: AudioRecorderClient) {
        self.recorderClient = recorderClient
    }

    func start() async {
        guard let recorderClient else { return }
        do {
            try await recorderClient.startRecording()
            state = .recording
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func stop() async {
        guard let recorderClient else { return }
        do {
            state = .processing
            lastRecordingURL = try await recorderClient.stopRecording()
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
