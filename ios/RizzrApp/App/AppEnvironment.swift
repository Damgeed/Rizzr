import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let apiClient: RizzrAPIClient
    let recorderClient: AudioRecorderClient
    let featureFlags: AppFeatureFlags

    init(
        apiClient: RizzrAPIClient,
        recorderClient: AudioRecorderClient,
        featureFlags: AppFeatureFlags
    ) {
        self.apiClient = apiClient
        self.recorderClient = recorderClient
        self.featureFlags = featureFlags
    }

    static let production = AppEnvironment(
        apiClient: RizzrAPIClient(configuration: .production),
        recorderClient: AVAudioRecorderClient(),
        featureFlags: .production
    )
}
