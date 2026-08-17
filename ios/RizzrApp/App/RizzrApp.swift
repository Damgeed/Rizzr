import SwiftUI

@main
struct RizzrApp: App {
    @StateObject private var environment = AppEnvironment.production

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(environment)
                .preferredColorScheme(.dark)
        }
    }
}
