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
        HStack(spacing: 0) {
            ForEach(RizzrMode.allCases) { mode in
                Button {
                    withAnimation(.snappy(duration: 0.26)) { selection.wrappedValue = mode }
                    RizzrHaptics.selection()
                } label: {
                    VStack(spacing: 9) {
                        Text(mode.title)
                            .font(.custom("Outfit", fixedSize: selection.wrappedValue == mode ? 21 : 19).weight(selection.wrappedValue == mode ? .black : .heavy))
                            .foregroundStyle(selection.wrappedValue == mode ? Color(hex: 0xFF006E) : Color(hex: 0x7C7C86))
                            .tracking(selection.wrappedValue == mode ? -0.28 : -0.08)
                            .shadow(color: selection.wrappedValue == mode ? Color(hex: 0xFF006E).opacity(0.52) : .clear, radius: 13, x: 0, y: 6)
                            .frame(maxWidth: .infinity)

                        ZStack {
                            Capsule()
                                .fill(Color.clear)
                                .frame(width: 58, height: 3.5)

                            if selection.wrappedValue == mode {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0xFF2A93), Color(hex: 0xFF006E)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 58, height: 3.5)
                                    .shadow(color: Color(hex: 0xFF006E).opacity(0.72), radius: 8, x: 0, y: -1)
                                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 21)
        .background(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0x30303A).opacity(0.95))
                .frame(height: 1)
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
