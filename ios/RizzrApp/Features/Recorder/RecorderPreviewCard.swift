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
        .accessibilityLabel(viewModel.state == .recording ? "Stop recording" : "Start recording")
    }

    private var helperText: some View {
        Text("Finesse is the live MVP. Ghost, Echo, and Vibe stay behind a clean feature boundary.")
            .font(RizzrTypography.body)
            .foregroundStyle(RizzrColor.textMuted)
            .multilineTextAlignment(.center)
    }

    private var labelText: String {
        switch viewModel.state {
        case .idle: "Tap to record"
        case .recording: "Listening…"
        case .processing: "Preparing replies…"
        case .failed: "Something went wrong"
        }
    }
}
