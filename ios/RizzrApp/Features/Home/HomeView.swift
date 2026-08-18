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
                    .padding(.top, 8)
                    .padding(.bottom, 26)

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
                .tracking(-1.25)
                .shadow(color: Color(hex: 0xFF1F6F).opacity(0.16), radius: 18, x: 0, y: 8)

            Spacer()

            HStack(spacing: 18) {
                Button { showSavedReplies = true } label: {
                    Image(systemName: "clock")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open history")

                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 25, weight: .bold))
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
            Color(hex: 0x000002)

            LinearGradient(
                colors: [Color(hex: 0x07040D), Color(hex: 0x010103), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0x7B18FF).opacity(0.30), .clear], center: .center, startRadius: 0, endRadius: 250))
                .frame(width: 430, height: 430)
                .blur(radius: 86)
                .offset(x: 160, y: 356)

            Circle()
                .fill(RadialGradient(colors: [Color(hex: 0xFF1F6F).opacity(0.16), Color(hex: 0x090016).opacity(0.05), .clear], center: .center, startRadius: 0, endRadius: 220))
                .frame(width: 360, height: 360)
                .blur(radius: 88)
                .offset(x: -172, y: 382)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview { HomeView().environmentObject(AppEnvironment.production) }
