import SwiftUI
import AVFoundation
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

    var body: some View {
        GlassCard {
            VStack(spacing: RizzrSpacing.lg) {
                header
                recordButton
                statusCopy
                progressViz
                repliesList
                if let previewError {
                    Text(previewError)
                        .font(RizzrTypography.caption)
                        .foregroundStyle(RizzrColor.textMuted)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
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
                    .fill(LinearGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 92, height: 92)
                    .shadow(color: RizzrColor.orbCoral.opacity(0.35), radius: 24)

                Image(systemName: viewModel.state == .recording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .disabled(isBusy)
        .accessibilityLabel(viewModel.state == .recording ? "Stop recording" : "Start recording")
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
            RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous)
                .fill(RizzrColor.glassFill)
                .frame(height: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous)
                        .fill(
                            LinearGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 110, height: 4),
                    alignment: .leading
                )
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

            if previewingReplyText == reply.text {
                Text("Playing")
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.orbCyan)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(RizzrSpacing.md)
        .background(RizzrColor.glassFill, in: RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: RizzrRadius.small, style: .continuous)
                .stroke(RizzrColor.glassBorder, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}
