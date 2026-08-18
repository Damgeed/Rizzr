import SwiftUI

struct ModeCarouselView: View {
    let featureFlags: AppFeatureFlags
    @State private var selectedMode: RizzrMode = .finesse

    var body: some View {
        VStack(alignment: .leading, spacing: RizzrSpacing.md) {
            Text("Modes")
                .font(RizzrTypography.caption)
                .foregroundStyle(RizzrColor.orbCoral)
                .textCase(.uppercase)
                .tracking(1.5)

            Picker("Mode", selection: $selectedMode) {
                ForEach(RizzrMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(RizzrColor.orbCoral)

            ModeCard(
                mode: selectedMode,
                isEnabled: featureFlags.isEnabled(selectedMode.featureGate)
            )
        }
    }
}

private struct ModeCard: View {
    let mode: RizzrMode
    let isEnabled: Bool

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
                HStack(spacing: RizzrSpacing.xs) {
                    Text(mode.title)
                        .font(RizzrTypography.title)
                        .foregroundStyle(.white)

                    Text(isEnabled ? "Live" : "Soon")
                        .font(RizzrTypography.caption)
                        .textCase(.uppercase)
                        .padding(.horizontal, RizzrSpacing.sm)
                        .padding(.vertical, RizzrSpacing.xxs)
                        .background(
                            LinearGradient(colors: isEnabled ? [RizzrColor.orbCoral, RizzrColor.orbViolet] : [Color.clear, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(isEnabled ? Color.clear : Color.yellow.opacity(0.35), lineWidth: 1))
                        .foregroundStyle(isEnabled ? .white : Color.yellow)
                }

                Text(mode.headline)
                    .font(RizzrTypography.bodyStrong)
                    .foregroundStyle(RizzrColor.textPrimary)

                Text(mode.description)
                    .font(RizzrTypography.body)
                    .foregroundStyle(RizzrColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

enum RizzrMode: String, CaseIterable, Identifiable, Hashable {
    case finesse
    case ghost
    case echo
    case vibe

    var id: String { rawValue }

    var featureGate: FeatureGate {
        switch self {
        case .finesse: .finesse
        case .ghost: .ghost
        case .echo: .echo
        case .vibe: .vibe
        }
    }

    var title: String {
        switch self {
        case .finesse: "Finesse"
        case .ghost: "Ghost"
        case .echo: "Echo"
        case .vibe: "Vibe"
        }
    }

    var headline: String {
        switch self {
        case .finesse: "Perfect replies, zero panic."
        case .ghost: "I want a graceful out"
        case .echo: "Sound like me, not a robot"
        case .vibe: "How are they really feeling?"
        }
    }

    var description: String {
        switch self {
        case .finesse:
            "Three confident replies tuned to their tone — flirty, witty, or sweet."
        case .ghost:
            "Fake call rings in right on cue — so you can exit awkward talks with zero explanation."
        case .echo:
            "Audio replies read in your voice, cloned and tuned to you."
        case .vibe:
            "Reads how they sound and tunes every reply to match the mood."
        }
    }
}
