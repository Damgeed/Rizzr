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
                        heroCopy
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
            .toolbarBackground(.hidden, for: .navigationBar)
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
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: RizzrColor.orbCoral.opacity(0.22), radius: 18, x: 0, y: 10)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("Rizzr")
                    .font(RizzrTypography.title)
                    .foregroundStyle(
                        LinearGradient(colors: [.white, RizzrColor.textMuted], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("AI voice-note reply coach")
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.textMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 2)
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
            Text("DON'T THINK. JUST RIZZR IT.")
                .font(RizzrTypography.caption)
                .tracking(1.8)
                .foregroundStyle(
                    LinearGradient(
                        colors: [RizzrColor.orbCoral, RizzrColor.orbViolet],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Perfect replies,\nzero panic.")
                .font(RizzrTypography.hero)
                .foregroundStyle(
                    LinearGradient(colors: [.white, RizzrColor.textMuted], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .tracking(-1.2)

            Text("Drop in a voice note and get three replies that match the moment—and still sound like you.")
                .font(RizzrTypography.body)
                .foregroundStyle(RizzrColor.textMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.production)
}
