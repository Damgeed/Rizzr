import SwiftUI

struct RecorderPreviewCard: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel

    var body: some View {
        GlassCard {
            VStack(spacing: RizzrSpacing.lg) {
                stateLabel
                recordButton
                helperText
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
        .disabled(viewModel.state == .processing)
        .accessibilityLabel(viewModel.state == .recording ? "Stop recording" : "Start recording")
    }

    private var helperText: some View {
        Text(helperCopy)
            .font(RizzrTypography.body)
            .foregroundStyle(RizzrColor.textMuted)
            .multilineTextAlignment(.center)
    }

    private var labelText: String {
        switch viewModel.state {
        case .idle: "Tap to record"
        case .recording: "Listening…"
        case .ready: "Voice note ready"
        case .processing: "Preparing replies…"
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
        case .failed(let message):
            message
        }
    }
}
