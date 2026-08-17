import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let apiClient: RizzrAPIClient
    let recorderClient: AudioRecorderClient

    init(apiClient: RizzrAPIClient, recorderClient: AudioRecorderClient) {
        self.apiClient = apiClient
        self.recorderClient = recorderClient
    }

    static let production = AppEnvironment(
        apiClient: RizzrAPIClient(configuration: .production),
        recorderClient: AVAudioRecorderClient()
    )
}
