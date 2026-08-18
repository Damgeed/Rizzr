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

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RizzrSpacing.lg) {
                        header
                        ModeCarouselView(featureFlags: environment.featureFlags)
                        RecorderPreviewCard(
                            viewModel: recorderViewModel,
                            savedRepliesStore: environment.savedRepliesStore
                        )
                    }
                    .padding(.horizontal, RizzrSpacing.md)
                    .padding(.top, RizzrSpacing.lg)
                    .padding(.bottom, RizzrSpacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showSavedReplies = true
                    } label: {
                        Image(systemName: "bookmark.fill")
                    }
                    .accessibilityLabel("Open saved replies")

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel("Open settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(environment)
            }
            .sheet(isPresented: $showSavedReplies) {
                SavedRepliesView()
                    .environmentObject(environment.savedRepliesStore)
            }
        }
        .task {
            recorderViewModel.configure(
                recorderClient: environment.recorderClient,
                apiClient: environment.apiClient
            )
        }
    }

    private var header: some View {
        HStack(spacing: RizzrSpacing.md) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Rizzr")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Voice replies, built for quick taps.")
                    .font(RizzrTypography.body)
                    .foregroundStyle(RizzrColor.textMuted)
            }

            Spacer(minLength: 0)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.production)
}
