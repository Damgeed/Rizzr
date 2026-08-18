import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let apiClient: RizzrAPIClient
    let recorderClient: AudioRecorderClient
    let featureFlags: AppFeatureFlags
    let savedRepliesStore: SavedRepliesStore

    init(
        apiClient: RizzrAPIClient,
        recorderClient: AudioRecorderClient,
        featureFlags: AppFeatureFlags,
        savedRepliesStore: SavedRepliesStore
    ) {
        self.apiClient = apiClient
        self.recorderClient = recorderClient
        self.featureFlags = featureFlags
        self.savedRepliesStore = savedRepliesStore
    }

    static let production = AppEnvironment(
        apiClient: RizzrAPIClient(configuration: .production),
        recorderClient: AVAudioRecorderClient(),
        featureFlags: .production,
        savedRepliesStore: SavedRepliesStore()
    )
}
