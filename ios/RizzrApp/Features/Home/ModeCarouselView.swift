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
                .padding(.bottom, 0)

            TabView(selection: selection) {
                FinesseModeView(viewModel: recorderViewModel, savedRepliesStore: savedRepliesStore).tag(RizzrMode.finesse)
                FinesseModeView(viewModel: recorderViewModel, savedRepliesStore: savedRepliesStore).tag(RizzrMode.echo)
                FinesseModeView(viewModel: recorderViewModel, savedRepliesStore: savedRepliesStore).tag(RizzrMode.ghost)
                FinesseModeView(viewModel: recorderViewModel, savedRepliesStore: savedRepliesStore).tag(RizzrMode.vibe)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var modeStrip: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(RizzrMode.allCases) { mode in
                    Button {
                        withAnimation(.snappy(duration: 0.26)) { selection.wrappedValue = mode }
                        RizzrHaptics.selection()
                    } label: {
                        Text(mode.title)
                            .font(.custom("Outfit", fixedSize: 18).weight(.heavy))
                            .foregroundStyle(selection.wrappedValue == mode ? Color(hex: 0xFF0A78) : Color(hex: 0x74747F))
                            .shadow(color: selection.wrappedValue == mode ? Color(hex: 0xFF0A78).opacity(0.36) : .clear, radius: 12, x: 0, y: 6)
                            .frame(maxWidth: .infinity)
                            .frame(height: 39)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 21)

            GeometryReader { proxy in
                let tabWidth = proxy.size.width / CGFloat(RizzrMode.allCases.count)
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(height: 1)

                    Rectangle()
                        .fill(Color(hex: 0xFF0A78))
                        .frame(width: tabWidth, height: 3)
                        .offset(x: tabWidth * CGFloat(selection.wrappedValue.index))
                        .animation(.snappy(duration: 0.26), value: selection.wrappedValue)
                }
            }
            .frame(height: 2)
            .padding(.horizontal, 21)
        }
    }
}

private struct FinesseModeView: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel
    @ObservedObject var savedRepliesStore: SavedRepliesStore

    var body: some View {
        ScrollView(showsIndicators: false) {
            RecorderPreviewCard(viewModel: viewModel, savedRepliesStore: savedRepliesStore)
                .padding(.horizontal, 26)
                .padding(.top, 76)
                .padding(.bottom, 34)
        }
    }
}

struct OutlinePill: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.custom("Outfit", fixedSize: 16).weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color(hex: 0x101014).opacity(0.76), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle())
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
    var index: Int { Self.allCases.firstIndex(of: self) ?? 0 }
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
