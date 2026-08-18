import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct RecorderPreviewCard: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel
    @ObservedObject var savedRepliesStore: SavedRepliesStore
    @State private var copiedReplyID: String?
    @State private var previewReplyID: String?
    @State private var previewPlayer: AVAudioPlayer?
    @State private var previewError: String?
    @State private var previewingReplyText: String?
    @State private var showAudioImporter = false
    @State private var showTextInput = false
    @State private var typedText = ""

    var body: some View {
        VStack(spacing: 0) {
            recordButton

            Text(labelText)
                .font(.custom("Outfit", fixedSize: 13).weight(.black))
                .tracking(2.65)
                .foregroundStyle(Color(hex: 0xB7B7C6))
                .shadow(color: .black.opacity(0.8), radius: 12, x: 0, y: 6)
                .padding(.top, 31)

            readyAction
                .padding(.top, 22)

            progressViz
                .padding(.top, 18)

            HStack(spacing: 12) {
                Button { showAudioImporter = true } label: {
                    Label("Upload audio", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(RizzrGradientActionStyle())

                Button { showTextInput = true } label: {
                    Label("Type text", systemImage: "keyboard")
                }
                .buttonStyle(RizzrOutlineActionStyle())
            }
            .font(.custom("Outfit", fixedSize: 15).weight(.bold))
            .foregroundStyle(.white)
            .padding(.top, 64)
            .disabled(isBusy || viewModel.state == .recording)
            .opacity(shouldShowImportAction ? 1 : 0.45)

            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(height: 1)
                .padding(.top, 28)

            FeatureBadgeRow()
                .padding(.top, 31)

            repliesList
                .padding(.top, 24)

            if let previewError {
                Text(previewError)
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .fileImporter(
            isPresented: $showAudioImporter,
            allowedContentTypes: [.audio, .mpeg4Audio, .mp3, .wav],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await viewModel.importRecording(from: url) }
            case .failure(let error):
                previewError = error.localizedDescription
            }
        }
        .sheet(isPresented: $showTextInput) {
            NavigationStack {
                VStack(spacing: RizzrSpacing.lg) {
                    TextEditor(text: $typedText)
                        .font(RizzrTypography.body)
                        .padding(RizzrSpacing.sm)
                        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: RizzrRadius.medium))
                        .overlay(RoundedRectangle(cornerRadius: RizzrRadius.medium).stroke(RizzrColor.glassBorder))
                    Button("Get replies") {
                        showTextInput = false
                        Task { await viewModel.generateReplies(from: typedText) }
                    }
                    .font(RizzrTypography.bodyStrong)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, RizzrSpacing.md)
                    .background(RizzrReferenceGradient.gradient, in: Capsule())
                    .disabled(typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(RizzrSpacing.lg)
                .background(RizzrBackground())
                .navigationTitle("Type text")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showTextInput = false } } }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var recordButton: some View {
        Button {
            Task {
                switch viewModel.state {
                case .recording:
                    await viewModel.stop()
                default:
                    await viewModel.start()
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(RizzrReferenceGradient.gradient)
                    .frame(width: 192, height: 192)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.34), .white.opacity(0.06)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color(hex: 0xFF0A78).opacity(0.78), radius: 34, x: -12, y: -8)
                    .shadow(color: Color(hex: 0x5316FF).opacity(0.82), radius: 54, x: 18, y: 24)
                    .shadow(color: Color(hex: 0xFF0A78).opacity(0.18), radius: 8, x: 0, y: 2)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.18), .clear],
                            center: .topLeading,
                            startRadius: 4,
                            endRadius: 118
                        )
                    )
                    .frame(width: 192, height: 192)
                    .blendMode(.screen)

                Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 68, weight: .black))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.26), radius: 8, x: 0, y: 4)
            }
        }
        .buttonStyle(RecordButtonStyle())
        .disabled(isBusy)
        .accessibilityLabel(viewModel.state == .recording ? "Stop recording" : "Start recording")
    }

    @ViewBuilder
    private var readyAction: some View {
        if case .ready = viewModel.state {
            Button {
                Task { await viewModel.generateReplies() }
            } label: {
                Label("Get replies", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .font(.custom("Outfit", fixedSize: 15).weight(.semibold))
            .foregroundStyle(.white)
            .frame(height: 54)
            .background(RizzrReferenceGradient.gradient, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    @ViewBuilder
    private var progressViz: some View {
        switch viewModel.state {
        case .recording:
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { index in
                    Capsule()
                        .fill(RizzrReferenceGradient.gradient)
                        .frame(width: 5, height: [18, 34, 58, 28, 44, 24, 50][index])
                }
            }
            .padding(.vertical, RizzrSpacing.xs)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var repliesList: some View {
        if case .complete(let replies) = viewModel.state {
            VStack(spacing: RizzrSpacing.sm) {
                ForEach(replies) { reply in
                    ReplyCard(
                        reply: reply,
                        isCopied: copiedReplyID == reply.id,
                        isPreviewing: previewReplyID == reply.id,
                        isSaved: savedRepliesStore.isSaved(reply),
                        onCopy: { copy(reply) },
                        onPreview: { preview(reply) },
                        onToggleSaved: { savedRepliesStore.toggle(reply) }
                    )
                }
            }
        }
    }

    private var labelText: String {
        switch viewModel.state {
        case .idle: "TAP TO RECORD"
        case .recording: "LISTENING…"
        case .ready: "VOICE NOTE READY"
        case .processing: "PREPARING…"
        case .transcribing: "TRANSCRIBING…"
        case .generating: "WRITING REPLIES…"
        case .complete: "REPLIES READY"
        case .failed: "TRY AGAIN"
        }
    }

    private var shouldShowImportAction: Bool {
        switch viewModel.state {
        case .idle, .ready, .failed:
            true
        default:
            false
        }
    }

    private var isBusy: Bool {
        switch viewModel.state {
        case .processing, .transcribing, .generating:
            true
        default:
            false
        }
    }

    private func copy(_ reply: ReplySuggestion) {
        #if canImport(UIKit)
        UIPasteboard.general.string = reply.text
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        copiedReplyID = reply.id
        #endif
    }

    private func preview(_ reply: ReplySuggestion) {
        previewError = nil
        previewingReplyText = reply.text
        Task {
            do {
                let url = try await viewModel.generateAudioPreview(for: reply.text)
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.play()
                await MainActor.run {
                    previewPlayer = player
                    previewReplyID = reply.id
                }
                let duration = max(player.duration, 0.5)
                try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                await MainActor.run {
                    if previewReplyID == reply.id { previewReplyID = nil }
                    if previewingReplyText == reply.text { previewingReplyText = nil }
                }
            } catch {
                await MainActor.run {
                    previewError = error.localizedDescription
                    previewingReplyText = nil
                }
            }
        }
    }
}

private enum RizzrReferenceGradient {
    static var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xFF006E), Color(hex: 0xC100FF), Color(hex: 0x4A00FF)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct FeatureBadgeRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            FeatureBadge(icon: "lock.fill", title: "No Signup")
            FeatureBadge(icon: "bolt.fill", title: "~7s Results")
            FeatureBadge(icon: "globe", title: "Any Language")
        }
    }
}

private struct FeatureBadge: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(.white)
                .frame(height: 22)
            Text(title)
                .font(.custom("Outfit", fixedSize: 13).weight(.bold))
                .foregroundStyle(Color(hex: 0xEEEEF4))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct RecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

private struct RizzrGradientActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(RizzrReferenceGradient.gradient, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
            .shadow(color: Color(hex: 0xFF0A78).opacity(configuration.isPressed ? 0.22 : 0.38), radius: 18, x: 0, y: 10)
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct RizzrOutlineActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(hex: 0x06060A).opacity(configuration.isPressed ? 1 : 0.94), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color.white.opacity(0.30), lineWidth: 1.15))
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct ReplyCard: View {
    let reply: ReplySuggestion
    let isCopied: Bool
    let isPreviewing: Bool
    let isSaved: Bool
    let onCopy: () -> Void
    let onPreview: () -> Void
    let onToggleSaved: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
            HStack(spacing: RizzrSpacing.sm) {
                Text(reply.style.rawValue.capitalized)
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.orbCyan)
                    .textCase(.uppercase)

                Spacer()

                Button(action: onPreview) {
                    Label(isPreviewing ? "Playing" : "Play", systemImage: isPreviewing ? "speaker.wave.2.fill" : "play.fill")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(isPreviewing ? RizzrColor.orbCyan : RizzrColor.textMuted)
                .disabled(isPreviewing)
                .accessibilityLabel(isPreviewing ? "Playing audio preview" : "Preview audio")

                Button(action: onCopy) {
                    Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(isCopied ? RizzrColor.orbCyan : RizzrColor.textMuted)
                .accessibilityLabel(isCopied ? "Copied reply" : "Copy reply")

                Button(action: onToggleSaved) {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(isSaved ? RizzrColor.orbCoral : RizzrColor.textMuted)
                .accessibilityLabel(isSaved ? "Remove saved reply" : "Save reply")

                ShareLink(item: reply.text) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(RizzrColor.textMuted)
                .accessibilityLabel("Share reply")
            }

            Text(reply.text)
                .font(RizzrTypography.body)
                .foregroundStyle(RizzrColor.textPrimary)
                .textSelection(.enabled)

            if isPreviewing {
                Text("Playing")
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.orbCyan)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RizzrSpacing.md)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous))
        .background(RizzrColor.glassFill, in: RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous)
                .stroke(RizzrColor.glassBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
