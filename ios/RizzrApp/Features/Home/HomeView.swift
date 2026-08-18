import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var recorderViewModel = VoiceRecorderViewModel()
    @State private var showSettings = false
    @State private var showSavedReplies = false

    var body: some View {
        ZStack {
            RizzrReferenceBackground()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 25)
                    .padding(.top, 10)
                    .padding(.bottom, 30)

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
        HStack(alignment: .center, spacing: 0) {
            Text("Rizzr")
                .font(RizzrTypography.logo)
                .foregroundStyle(.white)
                .tracking(-0.35)

            Spacer()

            HStack(spacing: 18) {
                Button { showSavedReplies = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 23, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open history")

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
            }
        }
    }
}

private struct RizzrReferenceBackground: View {
    var body: some View {
        ZStack {
            Color(hex: 0x050506)

            LinearGradient(
                colors: [Color.black.opacity(0.10), Color(hex: 0x0A0910).opacity(0.86), Color.black.opacity(0.96)],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x29104A).opacity(0.34), .clear], center: .center, startRadius: 0, endRadius: 220))
                .frame(width: 360, height: 360)
                .blur(radius: 70)
                .offset(x: 155, y: 365)

            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x08213F).opacity(0.20), .clear], center: .center, startRadius: 0, endRadius: 190))
                .frame(width: 310, height: 310)
                .blur(radius: 74)
                .offset(x: -170, y: 380)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview { HomeView().environmentObject(AppEnvironment.production) }
