import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var recorderViewModel = VoiceRecorderViewModel()
    @State private var showSettings = false
    @State private var showSavedReplies = false

    var body: some View {
        ZStack {
            RizzrBackground()
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    .padding(.bottom, 18)
                ModeCarouselView(
                    featureFlags: environment.featureFlags,
                    recorderViewModel: recorderViewModel,
                    savedRepliesStore: environment.savedRepliesStore
                )
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(environment) }
        .sheet(isPresented: $showSavedReplies) { SavedRepliesView().environmentObject(environment.savedRepliesStore) }
        .task {
            recorderViewModel.configure(recorderClient: environment.recorderClient, apiClient: environment.apiClient)
        }
    }

    private var header: some View {
        HStack {
            Text("Rizzr")
                .font(RizzrTypography.logo)
                .foregroundStyle(.white)
            Spacer()
            Menu {
                Button("Saved replies", systemImage: "bookmark") { showSavedReplies = true }
                Button("Settings", systemImage: "gearshape") { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.055), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.07)))
            }
            .accessibilityLabel("Open app menu")
        }
    }
}

#Preview { HomeView().environmentObject(AppEnvironment.production) }
