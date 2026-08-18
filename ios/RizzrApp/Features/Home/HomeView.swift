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
                colors: [Color(hex: 0x07070A), Color(hex: 0x040407), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x45119B).opacity(0.38), .clear], center: .center, startRadius: 0, endRadius: 230))
                .frame(width: 390, height: 390)
                .blur(radius: 78)
                .offset(x: 156, y: 372)

            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x062B66).opacity(0.24), .clear], center: .center, startRadius: 0, endRadius: 205))
                .frame(width: 340, height: 340)
                .blur(radius: 82)
                .offset(x: -178, y: 388)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview { HomeView().environmentObject(AppEnvironment.production) }
