import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var recorderViewModel = VoiceRecorderViewModel()
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                RizzrBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: RizzrSpacing.xl) {
                        hero
                        ModeCarouselView(featureFlags: environment.featureFlags)
                        RecorderPreviewCard(viewModel: recorderViewModel)
                        workflowSteps
                    }
                    .padding(.horizontal, RizzrSpacing.md)
                    .padding(.top, RizzrSpacing.lg)
                    .padding(.bottom, RizzrSpacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
        }
        .task {
            recorderViewModel.configure(
                recorderClient: environment.recorderClient,
                apiClient: environment.apiClient
            )
        }
    }

    private var hero: some View {
        VStack(spacing: RizzrSpacing.sm) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .accessibilityHidden(true)

            Text("Rizzr")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Don’t think. Just Rizzr it.")
                .font(RizzrTypography.title)
                .multilineTextAlignment(.center)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, RizzrColor.textMuted],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Rizzr turns voice notes into confident, natural replies that sound like you — in seconds.")
                .font(RizzrTypography.body)
                .foregroundStyle(RizzrColor.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(3)

            HStack(spacing: RizzrSpacing.sm) {
                trustPill("No Signup")
                trustPill("~7s Results")
                trustPill("Any Language")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var workflowSteps: some View {
        VStack(alignment: .leading, spacing: RizzrSpacing.md) {
            Text("How it works")
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.orbCoral)
                .textCase(.uppercase)
                .tracking(1.5)

            VStack(spacing: RizzrSpacing.sm) {
                step(number: "01", title: "Record or drop it in", body: "Hold the mic, upload a file, or paste a link to the voice note you got.")
                step(number: "02", title: "Rizzr listens", body: "We transcribe it and read the tone — what they said and how they said it.")
                step(number: "03", title: "Pick your reply", body: "Flirty, witty, or sweet — each one written out and ready to copy or share.")
            }
        }
    }

    private func trustPill(_ text: String) -> some View {
        Text(text)
            .font(RizzrTypography.caption)
            .foregroundStyle(RizzrColor.textPrimary)
            .padding(.horizontal, RizzrSpacing.sm)
            .padding(.vertical, RizzrSpacing.xs)
            .background(RizzrColor.glassFill, in: Capsule())
            .overlay(Capsule().stroke(RizzrColor.glassBorder, lineWidth: 1))
    }

    private func step(number: String, title: String, body: String) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: RizzrSpacing.md) {
                Text(number)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(RizzrColor.orbCoral)
                    .opacity(0.9)

                VStack(alignment: .leading, spacing: RizzrSpacing.xs) {
                    Text(title)
                        .font(RizzrTypography.bodyStrong)
                        .foregroundStyle(.white)
                    Text(body)
                        .font(RizzrTypography.body)
                        .foregroundStyle(RizzrColor.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.production)
}
