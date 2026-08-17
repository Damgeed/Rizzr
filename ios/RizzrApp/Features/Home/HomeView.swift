import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var recorderViewModel = VoiceRecorderViewModel()

    var body: some View {
        ZStack {
            RizzrBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: RizzrSpacing.xl) {
                    header
                    ModeCarouselView(featureFlags: environment.featureFlags)
                    RecorderPreviewCard(viewModel: recorderViewModel)
                }
                .padding(.horizontal, RizzrSpacing.md)
                .padding(.top, RizzrSpacing.lg)
                .padding(.bottom, RizzrSpacing.xxl)
            }
        }
        .task {
            recorderViewModel.configure(recorderClient: environment.recorderClient)
        }
    }

    private var header: some View {
        VStack(spacing: RizzrSpacing.sm) {
            Text("Rizzr")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Don’t think. Just Rizzr it.")
                .font(RizzrTypography.display)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, RizzrColor.textMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Send a voice note. Rizzr writes 3 perfect replies back — in seconds.")
                .font(RizzrTypography.body)
                .foregroundStyle(RizzrColor.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.production)
}
