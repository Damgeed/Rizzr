import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var recorderViewModel = VoiceRecorderViewModel()
    @State private var showSettings = false
    @State private var showSavedReplies = false

    var body: some View {
        NavigationStack {
            ZStack {
                RizzrBackground()
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, RizzrSpacing.lg)
                        .padding(.top, RizzrSpacing.sm)
                    ModeCarouselView(
                        featureFlags: environment.featureFlags,
                        recorderViewModel: recorderViewModel,
                        savedRepliesStore: environment.savedRepliesStore
                    )
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showSavedReplies = true } label: { Image(systemName: "bookmark") }
                        .accessibilityLabel("Open saved replies")
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Open settings")
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView().environmentObject(environment) }
            .sheet(isPresented: $showSavedReplies) { SavedRepliesView().environmentObject(environment.savedRepliesStore) }
        }
        .task {
            recorderViewModel.configure(recorderClient: environment.recorderClient, apiClient: environment.apiClient)
        }
    }

    private var header: some View {
        HStack(spacing: RizzrSpacing.sm) {
            Image("BrandMark")
                .resizable().scaledToFit().frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .accessibilityHidden(true)
            Text("Rizzr").font(RizzrTypography.title).foregroundStyle(.white)
            Spacer()
        }
    }
}

#Preview { HomeView().environmentObject(AppEnvironment.production) }
