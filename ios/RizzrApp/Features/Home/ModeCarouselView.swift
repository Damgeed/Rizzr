import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

struct ModeCarouselView: View {
    let featureFlags: AppFeatureFlags
    @ObservedObject var recorderViewModel: VoiceRecorderViewModel
    @ObservedObject var savedRepliesStore: SavedRepliesStore
    @AppStorage("rizzr_selected_mode") private var selectedModeRaw = RizzrMode.finesse.rawValue

    private var selection: Binding<RizzrMode> {
        Binding(get: { RizzrMode(rawValue: selectedModeRaw) ?? .finesse }, set: { selectedModeRaw = $0.rawValue })
    }

    var body: some View {
        VStack(spacing: 0) {
            modeStrip
            TabView(selection: selection) {
                FinesseModeView(viewModel: recorderViewModel, savedRepliesStore: savedRepliesStore).tag(RizzrMode.finesse)
                EchoModeView().tag(RizzrMode.echo)
                GhostModeView().tag(RizzrMode.ghost)
                VibeModeView(viewModel: recorderViewModel).tag(RizzrMode.vibe)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var modeStrip: some View {
        HStack(spacing: 0) {
            ForEach(RizzrMode.allCases) { mode in
                Button {
                    withAnimation(.snappy(duration: 0.32)) { selection.wrappedValue = mode }
                    RizzrHaptics.selection()
                } label: {
                    VStack(spacing: 9) {
                        Text(mode.title).font(RizzrTypography.body)
                            .foregroundStyle(selection.wrappedValue == mode ? RizzrColor.orbCoral : Color.white.opacity(0.62))
                        Circle().fill(selection.wrappedValue == mode ? RizzrColor.orbCoral : .clear).frame(width: 6, height: 6)
                    }.frame(maxWidth: .infinity).contentShape(Rectangle())
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24).padding(.bottom, 4)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.065)).frame(height: 1).padding(.horizontal, 24) }
    }
}

private struct ScreenLayout<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ScrollView(showsIndicators: false) {
            content.frame(maxWidth: .infinity).padding(.horizontal, 26).padding(.top, 58).padding(.bottom, 36)
        }
    }
}

private struct ModeTitle: View {
    let text: String
    let subtitle: String?
    init(_ text: String, subtitle: String? = nil) { self.text = text; self.subtitle = subtitle }
    var body: some View {
        VStack(spacing: 44) {
            Text(text).font(RizzrTypography.hero).foregroundStyle(.white).multilineTextAlignment(.center)
                .tracking(-1.25).lineSpacing(-5)
                .minimumScaleFactor(0.78)
                .accessibilityAddTraits(.isHeader)
            if let subtitle {
                Text(subtitle).font(RizzrTypography.body).foregroundStyle(Color.white.opacity(0.62)).multilineTextAlignment(.center)
            }
        }
    }
}

private struct FinesseModeView: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel
    @ObservedObject var savedRepliesStore: SavedRepliesStore
    var body: some View {
        ScreenLayout {
            VStack(spacing: 48) {
                ModeTitle("Perfect replies,\nzero panic.")
                RecorderPreviewCard(viewModel: viewModel, savedRepliesStore: savedRepliesStore)
            }
        }
    }
}

private struct EchoModeView: View {
    @State private var showTextInput = false
    var body: some View {
        ScreenLayout {
            VStack(spacing: 0) {
                ModeTitle("Sound like\nyou.")
                SpectrumWaveform().frame(height: 118).padding(.top, 72)
                Text("0:07").font(RizzrTypography.body).foregroundStyle(Color.white.opacity(0.7)).padding(.top, 19)
                GradientPill(title: "Create voice reply", icon: "waveform") {}.padding(.top, 35)
                OrDivider().padding(.vertical, 29)
                OutlinePill(title: "Type text", icon: "text.line.first.and.arrowtriangle.forward") { showTextInput = true }
            }
        }
        .sheet(isPresented: $showTextInput) { RizzrTextInputSheet(title: "Create voice reply") }
    }
}

private struct GhostModeView: View {
    @State private var day = "Today"
    @State private var hour = "9:41"
    @State private var period = "AM"
    var body: some View {
        ScreenLayout {
            VStack(spacing: 0) {
                ModeTitle("Your exit,\nright on cue.", subtitle: "Schedule a fake incoming call.")
                GhostPicker(day: $day, hour: $hour, period: $period).padding(.top, 45)
                OutlinePill(title: "Set fake call", icon: "phone") { RizzrHaptics.success() }.padding(.top, 68)
                Label("Calls are local to your device.\nNo one is notified.", systemImage: "shield")
                    .font(RizzrTypography.caption).foregroundStyle(Color.white.opacity(0.5)).padding(.top, 34)
            }
        }
    }
}

private struct VibeModeView: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel
    @State private var showTextInput = false
    @State private var showImporter = false
    var body: some View {
        ScreenLayout {
            VStack(spacing: 0) {
                ModeTitle("Read the\nroom.")
                AudioOrb(isRecording: isRecording) {
                    Task {
                        if isRecording { await viewModel.stop() }
                        else { await viewModel.start() }
                    }
                }
                    .padding(.top, 59)
                Text(isRecording ? "Tap to stop" : "Tap to record").font(RizzrTypography.body)
                    .foregroundStyle(Color.white.opacity(0.66)).padding(.top, 22)
                OrDivider().padding(.top, 60).padding(.bottom, 30)
                HStack(spacing: 12) {
                    OutlinePill(title: "Upload audio", icon: "square.and.arrow.up") { showImporter = true }
                    OutlinePill(title: "Paste text", icon: "doc.on.clipboard") { showTextInput = true }
                }
                Label("Audio gives richer\ntone analysis.", systemImage: "sparkles")
                    .font(RizzrTypography.caption).foregroundStyle(Color.white.opacity(0.48)).padding(.top, 34)
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.audio], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first { Task { await viewModel.importRecording(from: url) } }
        }
        .sheet(isPresented: $showTextInput) { RizzrTextInputSheet(title: "Read the room") }
    }
    private var isRecording: Bool { if case .recording = viewModel.state { return true }; return false }
}

private struct AudioOrb: View {
    let isRecording: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().trim(from: 0.02, to: 0.98)
                    .stroke(AngularGradient(colors: [RizzrColor.orbCoral, RizzrColor.orbViolet, RizzrColor.orbCoral], center: .center), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 7]))
                    .frame(width: 194, height: 194).rotationEffect(.degrees(isRecording ? 180 : 0))
                Circle().fill(Color.black.opacity(0.16)).frame(width: 164, height: 164)
                    .overlay(Circle().stroke(Color.white.opacity(0.46), lineWidth: 1))
                Image(systemName: isRecording ? "stop.fill" : "mic").font(.system(size: 48, weight: .medium)).foregroundStyle(RizzrColor.orbCoral)
            }
        }.buttonStyle(PressScaleStyle()).animation(.easeInOut(duration: 1.3), value: isRecording)
    }
}

private struct SpectrumWaveform: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let heights: [CGFloat] = [10,18,29,42,64,37,51,76,44,32,49,58,40,52,65,47,35,51,70,48,30,43,59,39,27,17,11]
    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 24.0, paused: reduceMotion)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 4) {
                ForEach(Array(heights.enumerated()), id: \.offset) { index, height in
                    Capsule()
                        .fill(LinearGradient(colors: spectrumColor(index), startPoint: .bottom, endPoint: .top))
                        .frame(width: 3, height: animatedHeight(height, index: index, phase: phase))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Seven second voice waveform")
    }
    private func animatedHeight(_ height: CGFloat, index: Int, phase: TimeInterval) -> CGFloat {
        guard !reduceMotion else { return height }
        let pulse = 0.90 + 0.10 * sin(phase * 2.4 + Double(index) * 0.54)
        return max(8, height * pulse)
    }
    private func spectrumColor(_ index: Int) -> [Color] {
        let p = Double(index) / Double(heights.count)
        if p < 0.38 { return [RizzrColor.orbCoral, Color(hex: 0xFF6D91)] }
        if p < 0.7 { return [RizzrColor.orbViolet, Color(hex: 0x7D71FF)] }
        return [RizzrColor.orbCyan, Color(hex: 0x22E7FF)]
    }
}

private struct GhostPicker: View {
    @Binding var day: String
    @Binding var hour: String
    @Binding var period: String
    var body: some View {
        HStack(spacing: 0) {
            Picker("Day", selection: $day) { Text("Today").tag("Today"); Text("Tomorrow").tag("Tomorrow") }
            Divider().overlay(Color.white.opacity(0.24)).frame(height: 72)
            Picker("Time", selection: $hour) { Text("9:41").tag("9:41"); Text("10:42").tag("10:42") }
            Divider().overlay(Color.white.opacity(0.24)).frame(height: 72)
            Picker("Period", selection: $period) { Text("AM").tag("AM"); Text("PM").tag("PM") }
        }
        .pickerStyle(.wheel).frame(height: 108).clipped()
        .background(Color.black.opacity(0.15), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.28)))
    }
}

private struct OrDivider: View {
    var body: some View {
        HStack(spacing: 16) {
            Rectangle().fill(Color.white.opacity(0.13)).frame(height: 1)
            Text("OR").font(RizzrTypography.caption).foregroundStyle(Color.white.opacity(0.55))
            Rectangle().fill(Color.white.opacity(0.13)).frame(height: 1)
        }
    }
}

struct OutlinePill: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(RizzrTypography.bodyStrong).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color.white.opacity(0.025), in: Capsule()).overlay(Capsule().stroke(Color.white.opacity(0.22)))
        }.buttonStyle(PressScaleStyle()).contentShape(Capsule())
    }
}

private struct GradientPill: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon).font(RizzrTypography.bodyStrong).foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 58)
                .background(LinearGradient(colors: [Color(hex: 0xA5164B).opacity(0.84), Color(hex: 0x171722).opacity(0.9)], startPoint: .leading, endPoint: .trailing), in: Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.08)))
        }.buttonStyle(PressScaleStyle())
    }
}

private struct RizzrTextInputSheet: View {
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    var body: some View {
        NavigationStack {
            ZStack {
                RizzrBackground()
                TextEditor(text: $text).font(RizzrTypography.body).scrollContentBackground(.hidden).padding(20).foregroundStyle(.white)
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.preferredColorScheme(.dark)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

enum RizzrMode: String, CaseIterable, Identifiable, Hashable {
    case finesse, echo, ghost, vibe
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum RizzrHaptics {
    static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}
