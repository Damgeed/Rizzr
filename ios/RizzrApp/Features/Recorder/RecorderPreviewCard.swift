import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RecorderPreviewCard: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel
    @State private var copiedReplyID: String?

    var body: some View {
        GlassCard {
            VStack(spacing: RizzrSpacing.lg) {
                stateLabel
                primaryAction
                helperText
                repliesList
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var stateLabel: some View {
        Text(labelText)
            .font(RizzrTypography.bodyStrong)
            .foregroundStyle(RizzrColor.textPrimary)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var primaryAction: some View {
        switch viewModel.state {
        case .ready:
            Button {
                Task { await viewModel.generateReplies() }
            } label: {
                Text("Generate replies")
                    .font(RizzrTypography.bodyStrong)
                    .foregroundStyle(.white)
                    .padding(.horizontal, RizzrSpacing.lg)
                    .padding(.vertical, RizzrSpacing.sm)
                    .background(
                        LinearGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Capsule()
                    )
            }
            .accessibilityLabel("Generate replies")

        case .complete:
            Button {
                copiedReplyID = nil
                viewModel.reset()
            } label: {
                Text("Record another")
                    .font(RizzrTypography.bodyStrong)
                    .foregroundStyle(.white)
                    .padding(.horizontal, RizzrSpacing.lg)
                    .padding(.vertical, RizzrSpacing.sm)
                    .background(RizzrColor.glassFill, in: Capsule())
                    .overlay(Capsule().stroke(RizzrColor.glassBorder, lineWidth: 1))
            }
            .accessibilityLabel("Record another voice note")

        default:
            recordButton
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

    private var helperText: some View {
        Text(helperCopy)
            .font(RizzrTypography.body)
            .foregroundStyle(RizzrColor.textMuted)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var repliesList: some View {
        if case .complete(let replies) = viewModel.state {
            VStack(spacing: RizzrSpacing.sm) {
                ForEach(replies) { reply in
                    ReplyCard(
                        reply: reply,
                        isCopied: copiedReplyID == reply.id,
                        onCopy: { copy(reply) }
                    )
                }
            }
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
        case .complete: "Replies ready"
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
            "Pick the one that sounds most like you. Copy or share when ready."
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
}

private struct ReplyCard: View {
    let reply: ReplySuggestion
    let isCopied: Bool
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
            HStack(spacing: RizzrSpacing.sm) {
                Text(reply.style.rawValue.capitalized)
                    .font(RizzrTypography.caption)
                    .foregroundStyle(RizzrColor.orbCyan)
                    .textCase(.uppercase)

                Spacer()

                Button(action: onCopy) {
                    Label(isCopied ? "Copied" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 15, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(isCopied ? RizzrColor.orbCyan : RizzrColor.textMuted)
                .accessibilityLabel(isCopied ? "Copied reply" : "Copy reply")

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
