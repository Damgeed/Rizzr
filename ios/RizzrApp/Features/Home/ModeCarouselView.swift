import SwiftUI

struct ModeCarouselView: View {
    private let modes: [RizzrMode] = RizzrMode.allCases

    var body: some View {
        TabView {
            ForEach(modes) { mode in
                ModeCard(mode: mode)
                    .padding(.horizontal, RizzrSpacing.xs)
            }
        }
        .frame(height: 194)
        .tabViewStyle(.page(indexDisplayMode: .automatic))
    }
}

private struct ModeCard: View {
    let mode: RizzrMode

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: RizzrSpacing.sm) {
                HStack(spacing: RizzrSpacing.xs) {
                    Text(mode.title)
                        .font(RizzrTypography.title)
                        .foregroundStyle(.white)

                    Text(mode.badge)
                        .font(RizzrTypography.caption)
                        .textCase(.uppercase)
                        .padding(.horizontal, RizzrSpacing.sm)
                        .padding(.vertical, RizzrSpacing.xxs)
                        .background(mode.isLive ? RizzrColor.orbCoral : Color.clear, in: Capsule())
                        .overlay(Capsule().stroke(mode.isLive ? Color.clear : Color.yellow.opacity(0.35), lineWidth: 1))
                        .foregroundStyle(mode.isLive ? .white : Color.yellow)
                }

                Text(mode.headline)
                    .font(RizzrTypography.bodyStrong)
                    .foregroundStyle(RizzrColor.textPrimary)

                Text(mode.description)
                    .font(RizzrTypography.body)
                    .foregroundStyle(RizzrColor.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

enum RizzrMode: String, CaseIterable, Identifiable {
    case finesse
    case ghost
    case echo
    case vibe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .finesse: "Finesse"
        case .ghost: "Ghost"
        case .echo: "Echo"
        case .vibe: "Vibe"
        }
    }

    var badge: String { isLive ? "Live" : "Soon" }
    var isLive: Bool { self == .finesse }

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
