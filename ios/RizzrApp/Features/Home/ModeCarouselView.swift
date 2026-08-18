import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ModeCarouselView: View {
    let featureFlags: AppFeatureFlags
    @ObservedObject var recorderViewModel: VoiceRecorderViewModel
    @ObservedObject var savedRepliesStore: SavedRepliesStore
    @AppStorage("rizzr_selected_mode") private var selectedModeRaw = RizzrMode.finesse.rawValue

    private var selection: Binding<RizzrMode> {
        Binding(
            get: { RizzrMode(rawValue: selectedModeRaw) ?? .finesse },
            set: { selectedModeRaw = $0.rawValue }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            selector
                .padding(.horizontal, RizzrSpacing.lg)
                .padding(.top, RizzrSpacing.lg)

            TabView(selection: selection) {
                FinesseModeView(viewModel: recorderViewModel, savedRepliesStore: savedRepliesStore).tag(RizzrMode.finesse)
                EchoModeView(isEnabled: featureFlags.isEnabled(.echo)).tag(RizzrMode.echo)
                GhostModeView(isEnabled: featureFlags.isEnabled(.ghost)).tag(RizzrMode.ghost)
                VibeModeView(isEnabled: featureFlags.isEnabled(.vibe)).tag(RizzrMode.vibe)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }

    private var selector: some View {
        HStack(spacing: 0) {
            ForEach(RizzrMode.allCases) { mode in
                Button {
                    selection.wrappedValue = mode
                    RizzrHaptics.selection()
                } label: {
                    VStack(spacing: 9) {
                        Text(mode.title)
                            .font(RizzrTypography.bodyStrong)
                            .foregroundStyle(selection.wrappedValue == mode ? RizzrColor.orbCoral : RizzrColor.textMuted)
                        Circle()
                            .fill(selection.wrappedValue == mode ? RizzrColor.orbCoral : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, RizzrSpacing.xs)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.white.opacity(0.07)).frame(height: 1) }
    }
}

private struct ModeTitle: View {
    let title: String
    let subtitle: String?
    init(_ title: String, subtitle: String? = nil) { self.title = title; self.subtitle = subtitle }

    var body: some View {
        VStack(spacing: RizzrSpacing.sm) {
            Text(title)
                .font(RizzrTypography.hero)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .tracking(-1.2)
            if let subtitle {
                Text(subtitle).font(RizzrTypography.body).foregroundStyle(RizzrColor.textMuted).multilineTextAlignment(.center)
            }
        }
    }
}

private struct FinesseModeView: View {
    @ObservedObject var viewModel: VoiceRecorderViewModel
    @ObservedObject var savedRepliesStore: SavedRepliesStore
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RizzrSpacing.xl) {
                ModeTitle("Perfect replies,\nzero panic.")
                RecorderPreviewCard(viewModel: viewModel, savedRepliesStore: savedRepliesStore)
            }
            .padding(.horizontal, RizzrSpacing.lg)
            .padding(.top, RizzrSpacing.xxl)
            .padding(.bottom, 80)
        }
    }
}

private struct EchoModeView: View {
    let isEnabled: Bool
    @State private var text = ""
    @State private var delivery = "Calm"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RizzrSpacing.xl) {
                ModeTitle("Sound like\nyou.")
                Label("Voice profile · Ready", systemImage: "waveform.circle.fill")
                    .font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)

                TextEditor(text: $text)
                    .font(RizzrTypography.body).foregroundStyle(.white).scrollContentBackground(.hidden)
                    .frame(minHeight: 112).padding(RizzrSpacing.md)
                    .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: RizzrRadius.medium, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: RizzrRadius.medium).stroke(RizzrColor.glassBorder))
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Say it like I would.").font(RizzrTypography.body).foregroundStyle(RizzrColor.textMuted)
                                .padding(RizzrSpacing.lg).allowsHitTesting(false)
                        }
                    }

                VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
                    Text("Delivery").font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                    HStack {
                        ForEach(["Calm", "Playful", "Confident"], id: \.self) { option in
                            ChoicePill(option, isSelected: delivery == option) { delivery = option }
                        }
                    }
                }
                PrimaryModeButton("Create voice reply", icon: "waveform", enabled: isEnabled && !text.isEmpty) {}
                Button("Update voice sample") {}.font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                if !isEnabled { PreviewNote() }
            }
            .padding(.horizontal, RizzrSpacing.xl).padding(.top, RizzrSpacing.xxl).padding(.bottom, 80)
        }
    }
}

private struct GhostModeView: View {
    let isEnabled: Bool
    @State private var delay = "Now"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RizzrSpacing.xl) {
                ModeTitle("Your exit,\nright on cue.")
                HStack {
                    Circle().fill(Color.white.opacity(0.10)).frame(width: 38, height: 38).overlay(Text("M"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Maya").font(RizzrTypography.bodyStrong)
                        Text("Change caller").font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(RizzrColor.textMuted)
                }
                .padding(RizzrSpacing.md)
                .background(Color.black.opacity(0.18), in: RoundedRectangle(cornerRadius: RizzrRadius.medium))
                .overlay(RoundedRectangle(cornerRadius: RizzrRadius.medium).stroke(RizzrColor.glassBorder))

                VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
                    Text("Delay").font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                    HStack {
                        ForEach(["Now", "30 sec", "1 min", "Custom"], id: \.self) { option in
                            ChoicePill(option, isSelected: delay == option) { delay = option }
                        }
                    }
                }
                HStack {
                    Label("Incoming call\nMaya", systemImage: "phone.fill")
                    Spacer()
                    Image(systemName: "phone.down.fill").foregroundStyle(.red)
                    Image(systemName: "phone.fill").foregroundStyle(.green)
                }
                .font(RizzrTypography.bodyStrong).padding(RizzrSpacing.md)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: RizzrRadius.medium))

                PrimaryModeButton("Set fake call", icon: "phone", enabled: isEnabled) {}
                Label("Runs locally on this device", systemImage: "shield")
                    .font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                if !isEnabled { PreviewNote() }
            }
            .padding(.horizontal, RizzrSpacing.xl).padding(.top, RizzrSpacing.xxl).padding(.bottom, 80)
        }
    }
}

private struct VibeModeView: View {
    let isEnabled: Bool
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: RizzrSpacing.xl) {
                ModeTitle("Read the\nroom.")
                Label("Voice note · 0:18", systemImage: "waveform")
                    .font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                VStack(spacing: 0) {
                    InsightRow(label: "Tone", value: "Warm but guarded")
                    InsightRow(label: "Intent", value: "Wants reassurance")
                    InsightRow(label: "Energy", value: "Low / thoughtful", hasDivider: false)
                }
                Label("High confidence", systemImage: "checkmark.circle")
                    .font(RizzrTypography.caption).foregroundStyle(.mint).frame(maxWidth: .infinity, alignment: .leading)
                Label("Reply gently. Don’t overplay it.", systemImage: "sparkles")
                    .font(RizzrTypography.bodyStrong).foregroundStyle(Color.yellow.opacity(0.88)).frame(maxWidth: .infinity, alignment: .leading)
                HStack {
                    PrimaryModeButton("Analyze another", icon: "arrow.triangle.2.circlepath", enabled: isEnabled) {}
                    Button("Paste text") {}.font(RizzrTypography.bodyStrong).foregroundStyle(.white)
                }
                Text("Audio gives richer tone analysis.").font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
                if !isEnabled { PreviewNote() }
            }
            .padding(.horizontal, RizzrSpacing.xl).padding(.top, RizzrSpacing.xxl).padding(.bottom, 80)
        }
    }
}

private struct InsightRow: View {
    let label: String
    let value: String
    var hasDivider = true
    var body: some View {
        HStack { Text(label); Spacer(); Text(value).foregroundStyle(RizzrColor.textMuted) }
            .font(RizzrTypography.body).padding(.vertical, RizzrSpacing.md)
            .overlay(alignment: .bottom) { if hasDivider { Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1) } }
    }
}

private struct ChoicePill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    init(_ title: String, isSelected: Bool, action: @escaping () -> Void) { self.title = title; self.isSelected = isSelected; self.action = action }
    var body: some View {
        Button(title, action: action)
            .font(RizzrTypography.caption).foregroundStyle(isSelected ? .white : RizzrColor.textMuted)
            .padding(.horizontal, RizzrSpacing.md).padding(.vertical, 9)
            .background(Color.white.opacity(isSelected ? 0.08 : 0.025), in: Capsule())
            .overlay(Capsule().stroke(isSelected ? RizzrColor.orbCoral : RizzrColor.glassBorder)).buttonStyle(.plain)
    }
}

private struct PrimaryModeButton: View {
    let title: String
    let icon: String
    let enabled: Bool
    let action: () -> Void
    init(_ title: String, icon: String, enabled: Bool, action: @escaping () -> Void) { self.title = title; self.icon = icon; self.enabled = enabled; self.action = action }
    var body: some View {
        Button(action: action) { Label(title, systemImage: icon).frame(maxWidth: .infinity) }
            .font(RizzrTypography.bodyStrong).foregroundStyle(.white).padding(.vertical, RizzrSpacing.md)
            .background(LinearGradient(colors: [RizzrColor.orbCoral.opacity(0.72), RizzrColor.orbViolet.opacity(0.34)], startPoint: .leading, endPoint: .trailing), in: Capsule())
            .opacity(enabled ? 1 : 0.45).disabled(!enabled)
    }
}

private struct PreviewNote: View {
    var body: some View {
        Text("Interactive preview · feature coming soon").font(RizzrTypography.caption).foregroundStyle(RizzrColor.textMuted)
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
}
