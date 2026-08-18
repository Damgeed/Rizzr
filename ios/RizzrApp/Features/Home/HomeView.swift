import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @StateObject private var recorderViewModel = VoiceRecorderViewModel()
    @State private var selectedMode: RizzrMode = .finesse
    @State private var showSettings = false
    @State private var showSavedReplies = false
    @State private var showAudioImporter = false
    @State private var selectedDelivery = "Calm"
    @State private var selectedDelay = "Now"

    private let tabOrder: [RizzrMode] = [.finesse, .echo, .ghost, .vibe]

    var body: some View {
        ZStack {
            RizzrBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                    modeTabs

                    Group {
                        switch selectedMode {
                        case .finesse:
                            finessePanel
                        case .echo:
                            echoPanel
                        case .ghost:
                            ghostPanel
                        case .vibe:
                            vibePanel
                        }
                    }
                    .padding(.top, 34)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 42)
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
        .fileImporter(
            isPresented: $showAudioImporter,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await recorderViewModel.importRecording(from: url) }
            }
        }
        .task {
            recorderViewModel.configure(
                recorderClient: environment.recorderClient,
                apiClient: environment.apiClient
            )
        }
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Text("Rizzr")
                .font(RizzrTypography.logo)
                .foregroundStyle(.white)

            Spacer()

            Menu {
                Button("Saved replies", systemImage: "bookmark") { showSavedReplies = true }
                Button("Settings", systemImage: "gearshape") { showSettings = true }
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RizzrColor.textMuted)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.035), in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
            .accessibilityLabel("Open app menu")
        }
    }

    private var modeTabs: some View {
        HStack(spacing: 0) {
            ForEach(tabOrder) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    VStack(spacing: 8) {
                        Text(mode.title)
                            .font(RizzrTypography.outfit(size: 15, weight: .semibold))
                            .foregroundStyle(selectedMode == mode ? RizzrColor.orbCoral : Color.white.opacity(0.64))

                        Circle()
                            .fill(selectedMode == mode ? RizzrColor.orbCoral : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 22)
                .padding(.leading, 4)
        }
        .padding(.top, 22)
    }

    private var finessePanel: some View {
        VStack(spacing: 28) {
            heroTitle("Perfect replies,\nzero panic.")

            Button {
                Task {
                    switch recorderViewModel.state {
                    case .recording:
                        await recorderViewModel.stop()
                    default:
                        await recorderViewModel.start()
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.09), lineWidth: 1)
                        .frame(width: 156, height: 156)

                    Circle()
                        .trim(from: 0.04, to: 0.92)
                        .stroke(
                            AngularGradient(
                                colors: [RizzrColor.orbCoral.opacity(0.15), RizzrColor.orbCoral, RizzrColor.orbViolet, RizzrColor.orbCoral.opacity(0.15)],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 8])
                        )
                        .frame(width: 138, height: 138)

                    Circle()
                        .fill(Color.white.opacity(0.025))
                        .frame(width: 104, height: 104)

                    Image(systemName: recorderViewModel.state == .recording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(RizzrColor.orbCoral)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(recorderViewModel.state == .recording ? "Stop recording" : "Start recording")

            Text(finesseStatus)
                .font(RizzrTypography.outfit(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.84))

            dividerLabel("OR")
                .padding(.top, 10)

            HStack(spacing: 12) {
                darkPillButton(title: "Upload audio", icon: "tray.and.arrow.up") {
                    showAudioImporter = true
                }
                darkPillButton(title: "Type text", icon: "text.alignleft") {}
            }

            if case .complete(let replies) = recorderViewModel.state {
                VStack(spacing: 10) {
                    ForEach(replies) { reply in
                        resultRow(reply.style.rawValue.capitalized, reply.text)
                    }
                }
                .padding(.top, 4)
            } else if case .ready = recorderViewModel.state {
                primaryButton(title: "Generate replies", icon: "sparkles") {
                    Task { await recorderViewModel.generateReplies() }
                }
            } else if case .failed(let message) = recorderViewModel.state {
                Text(message)
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.textMuted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var echoPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            heroTitle("Sound like\nyou.")
                .frame(maxWidth: .infinity)

            statusPill(icon: "waveform", text: "Voice profile · Ready", check: true)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 0) {
                Text("Say it like I would.")
                    .font(RizzrTypography.outfit(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.86))
                Spacer()
                Text("22 / 300")
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.textMuted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(height: 138)
            .padding(18)
            .background(cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.09), lineWidth: 1))

            optionSection(title: "Delivery", options: ["Calm", "Playful", "Confident"], selection: $selectedDelivery)

            primaryButton(title: "Create voice reply", icon: "waveform") {}
                .padding(.top, 4)

            Button("Update voice sample") {}
                .font(RizzrTypography.outfit(size: 15, weight: .semibold))
                .foregroundStyle(RizzrColor.textMuted)
                .frame(maxWidth: .infinity)
                .buttonStyle(.plain)
        }
    }

    private var ghostPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            heroTitle("Your exit,\nright on cue.")
                .frame(maxWidth: .infinity)

            HStack(spacing: 14) {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 42, height: 42)
                    .overlay(Text("M").font(RizzrTypography.bodyStrong).foregroundStyle(.white))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Maya")
                        .font(RizzrTypography.bodyStrong)
                        .foregroundStyle(.white)
                    Text("Change caller")
                        .font(RizzrTypography.caption)
                        .foregroundStyle(RizzrColor.textMuted)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(RizzrColor.textMuted)
            }
            .padding(16)
            .background(cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.09), lineWidth: 1))

            optionSection(title: "Delay", options: ["Now", "30 sec", "1 min", "Custom"], selection: $selectedDelay)

            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 42, height: 42)
                    .overlay(Image(systemName: "phone.fill").foregroundStyle(.green))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Incoming call")
                        .font(RizzrTypography.bodyStrong)
                        .foregroundStyle(.white)
                    Text("Maya")
                        .font(RizzrTypography.caption)
                        .foregroundStyle(RizzrColor.textMuted)
                }

                Spacer()
                callCircle(color: .red, icon: "phone.down.fill")
                callCircle(color: .green, icon: "phone.fill")
            }
            .padding(16)
            .background(cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.white.opacity(0.09), lineWidth: 1))

            Button {} label: {
                Label("Set fake call", systemImage: "phone")
                    .font(RizzrTypography.outfit(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.035), in: Capsule())
                    .overlay(Capsule().stroke(RizzrColor.orbCoral.opacity(0.45), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Label("Runs locally on this device", systemImage: "shield")
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.textMuted)
                .frame(maxWidth: .infinity)
        }
    }

    private var vibePanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            heroTitle("Read the\nroom.")
                .frame(maxWidth: .infinity)

            Label("Voice note · 0:18", systemImage: "waveform")
                .font(RizzrTypography.outfit(size: 15, weight: .medium))
                .foregroundStyle(RizzrColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 0) {
                analysisRow("Tone", "Warm but guarded")
                analysisRow("Intent", "Wants reassurance")
                analysisRow("Energy", "Low / thoughtful", divider: false)
            }

            Label("High confidence", systemImage: "checkmark.circle.fill")
                .font(RizzrTypography.outfit(size: 15, weight: .semibold))
                .foregroundStyle(.green)

            Label("Reply gently. Don’t overplay it.", systemImage: "sparkles")
                .font(RizzrTypography.bodyStrong)
                .foregroundStyle(.white)
                .labelStyle(.titleAndIcon)

            HStack(spacing: 12) {
                darkPillButton(title: "Analyze another", icon: "arrow.clockwise") {}
                darkPillButton(title: "Paste text", icon: "clipboard") {}
            }

            Label("Audio gives richer tone analysis.", systemImage: "sparkles")
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var finesseStatus: String {
        switch recorderViewModel.state {
        case .recording: "Listening…"
        case .processing: "Preparing recording…"
        case .ready: "Voice note ready"
        case .transcribing: "Transcribing voice note…"
        case .generating: "Writing replies…"
        case .complete: "Pick a reply"
        case .failed: "Try again"
        case .idle: "Tap to record"
        }
    }

    private var cardFill: Color { Color.white.opacity(0.025) }

    private func heroTitle(_ text: String) -> some View {
        Text(text)
            .font(RizzrTypography.outfit(size: 38, weight: .bold))
            .lineSpacing(1)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .tracking(-1.2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func dividerLabel(_ label: String) -> some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
            Text(label)
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.textMuted)
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    private func darkPillButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(RizzrTypography.outfit(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.84)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.025), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func primaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(RizzrTypography.outfit(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    LinearGradient(
                        colors: [RizzrColor.orbCoral.opacity(0.95), RizzrColor.orbViolet.opacity(0.72), Color.white.opacity(0.03)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule()
                )
                .shadow(color: RizzrColor.orbCoral.opacity(0.28), radius: 24, x: 0, y: 12)
        }
        .buttonStyle(.plain)
    }

    private func statusPill(icon: String, text: String, check: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(text)
            if check {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .font(RizzrTypography.caption)
        .foregroundStyle(RizzrColor.textMuted)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.03), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func optionSection(title: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RizzrTypography.outfit(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            HStack(spacing: 9) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection.wrappedValue = option
                    } label: {
                        Text(option)
                            .font(RizzrTypography.outfit(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(selection.wrappedValue == option ? 0.95 : 0.68))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.025), in: Capsule())
                            .overlay(Capsule().stroke(selection.wrappedValue == option ? RizzrColor.orbCoral.opacity(0.75) : Color.white.opacity(0.09), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func callCircle(color: Color, icon: String) -> some View {
        Circle()
            .fill(color.opacity(0.14))
            .frame(width: 36, height: 36)
            .overlay(Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(color))
    }

    private func analysisRow(_ label: String, _ value: String, divider: Bool = true) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(RizzrTypography.bodyStrong)
                    .foregroundStyle(.white)
                Spacer()
                Text(value)
                    .font(RizzrTypography.body)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
            .padding(.vertical, 14)

            if divider {
                Rectangle().fill(Color.white.opacity(0.09)).frame(height: 1)
            }
        }
    }

    private func resultRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.orbCoral)
                .textCase(.uppercase)
            Text(value)
                .font(RizzrTypography.body)
                .foregroundStyle(.white.opacity(0.88))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.09), lineWidth: 1))
    }
}

#Preview {
    HomeView()
        .environmentObject(AppEnvironment.production)
}
