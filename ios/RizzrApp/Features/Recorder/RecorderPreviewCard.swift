import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct RecorderPreviewCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: RizzrSpacing.lg) {
            recordButton
            statusCopy
            progressViz
            readyAction
            inputActions
            repliesList
            if let previewError {
                Text(previewError)
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.textMuted)
                    .multilineTextAlignment(.center)
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
                    .font(RizzrTypography.bodyStrong).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, RizzrSpacing.md)
                    .background(RizzrColor.orbCoral, in: Capsule())
                    .disabled(typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(RizzrSpacing.lg)
                .background(RizzrBackground())
                .navigationTitle("Type the message")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showTextInput = false } } }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear { isBreathing = !reduceMotion }
    }

    private var header: some View {
        VStack(spacing: RizzrSpacing.xs) {
            Text(cardTitle)
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.orbCyan)
                .textCase(.uppercase)
                .tracking(1.5)

            Text(labelText)
                .font(RizzrTypography.bodyStrong)
                .foregroundStyle(RizzrColor.textPrimary)
                .multilineTextAlignment(.center)
        }
    }

    @ViewBuilder
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
                    .stroke(RizzrColor.orbCoral.opacity(0.24), lineWidth: 1)
                    .frame(width: 184, height: 184)
                    .scaleEffect(isBreathing && viewModel.state == .idle ? 1.14 : 0.92)
                    .opacity(isBreathing && viewModel.state == .idle ? 0 : 0.8)

                Circle()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: 164, height: 164)
                    .overlay(Circle().stroke(Color.white.opacity(0.28), lineWidth: 1))

                Circle()
                    .trim(from: 0.06, to: 0.94)
                    .stroke(
                        AngularGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet, RizzrColor.orbCoral], center: .center),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 7])
                    )
                    .frame(width: 182, height: 182)

                Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(RizzrColor.orbCoral)
            }
        }
        .animation(
            reduceMotion ? nil : .easeOut(duration: 2.4).repeatForever(autoreverses: false),
            value: isBreathing
        )
        .buttonStyle(RecordButtonStyle())
        .disabled(isBusy)
        .accessibilityLabel(viewModel.state == .recording ? "Stop recording" : "Start recording")
    }

    private var inputActions: some View {
        HStack(spacing: RizzrSpacing.sm) {
            Button { showAudioImporter = true } label: {
                Label("Upload audio", systemImage: "square.and.arrow.up")
            }
            Button { showTextInput = true } label: {
                Label("Type text", systemImage: "text.alignleft")
            }
        }
        .font(RizzrTypography.caption)
        .foregroundStyle(RizzrColor.textPrimary)
        .buttonStyle(FinesseSecondaryButtonStyle())
        .disabled(isBusy || viewModel.state == .recording)
        .opacity(shouldShowImportAction ? 1 : 0)
    }

    @ViewBuilder
    private var readyAction: some View {
        if case .ready = viewModel.state {
            Button {
                Task { await viewModel.generateReplies() }
            } label: {
                Label("Get replies", systemImage: "sparkles").frame(maxWidth: .infinity)
            }
            .font(RizzrTypography.bodyStrong).foregroundStyle(.white)
            .padding(.vertical, RizzrSpacing.md)
            .background(RizzrColor.orbCoral.opacity(0.78), in: Capsule())
        }
    }

    private var statusCopy: some View {
        Text(helperCopy)
            .font(RizzrTypography.body)
            .foregroundStyle(RizzrColor.textMuted)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var progressViz: some View {
        switch viewModel.state {
        case .recording:
            HStack(spacing: 5) {
                ForEach(0..<7, id: \.self) { index in
                    Capsule()
                        .fill(LinearGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet], startPoint: .bottom, endPoint: .top))
                        .frame(width: 5, height: [18, 34, 58, 28, 44, 24, 50][index])
                }
            }
            .padding(.vertical, RizzrSpacing.xs)
        case .complete:
            EmptyView()
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

    private var cardTitle: String {
        switch viewModel.state {
        case .idle, .recording, .ready, .processing, .transcribing, .generating:
            "Quick reply"
        case .complete:
            "Replies ready"
        case .failed:
            "Try again"
        }
    }

    private var labelText: String {
        switch viewModel.state {
        case .idle: "Tap to record"
        case .recording: "Listening…"
        case .ready: "Voice note ready"
        case .processing: "Preparing recording…"
        case .transcribing: "Transcribing voice note…"
        case .generating: "Writing replies…"
        case .complete: "Pick the one that sounds most like you."
        case .failed: "Something went wrong"
        }
    }

    private var helperCopy: String {
        switch viewModel.state {
        case .idle:
            "Record a short voice note. Finesse turns it into flirty, witty, and sweet replies."
        case .recording:
            "Keep it natural. Short voice notes work best."
        case .ready(let recording):
            "Ready to process: \(recording.duration.formatted(.number.precision(.fractionLength(1))))s captured."
        case .processing:
            "Cleaning up the recording before reply generation."
        case .transcribing:
            "Turning the voice note into text."
        case .generating(let transcript):
            "Generating from: “\(transcript.prefix(80))”"
        case .complete:
            "Copy or preview audio when ready."
        case .failed(let message):
            message
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
                    if previewReplyID == reply.id {
                        previewReplyID = nil
                    }
                    if previewingReplyText == reply.text {
                        previewingReplyText = nil
                    }
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

private struct RecordButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.68), value: configuration.isPressed)
    }
}

private struct FinesseSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, RizzrSpacing.sm)
            .background(Color.black.opacity(configuration.isPressed ? 0.30 : 0.16), in: Capsule())
            .overlay(Capsule().stroke(RizzrColor.glassBorder))
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
