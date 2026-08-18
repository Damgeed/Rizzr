import SwiftUI

/// Native twin of the website's Midnight Aura background.
struct RizzrBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            ZStack {
                RizzrColor.background

                // CSS: 50vw, top -10%, left -10%.
                aura(RizzrColor.orbCoral, diameter: width * 0.50, opacity: 0.50)
                    .position(
                        x: width * 0.15 + drift(width * 0.50, amount: -0.05),
                        y: -height * 0.10 + width * 0.25 + drift(width * 0.50, amount: -0.05)
                    )

                // CSS: 60vw, bottom -20%, right -10%.
                aura(RizzrColor.orbViolet, diameter: width * 0.60, opacity: 0.50)
                    .position(
                        x: width * 0.80 + drift(width * 0.60, amount: 0.05),
                        y: height * 1.20 - width * 0.30 + drift(width * 0.60, amount: -0.05)
                    )

                // CSS: 40vw, top 40%, left 40%.
                aura(RizzrColor.orbCyan, diameter: width * 0.40, opacity: 0.30)
                    .position(
                        x: width * 0.60 + drift(width * 0.40, amount: -0.05),
                        y: height * 0.40 + width * 0.20 + drift(width * 0.40, amount: 0.10)
                    )
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 20).repeatForever(autoreverses: true), value: isFloating)
            .onAppear { isFloating = !reduceMotion }
        }
        .ignoresSafeArea()
        .overlay { RizzrNoiseOverlay().opacity(0.14).ignoresSafeArea() }
        .accessibilityHidden(true)
    }

    private func drift(_ diameter: CGFloat, amount: CGFloat) -> CGFloat {
        isFloating ? diameter * amount : 0
    }

    private func aura(_ color: Color, diameter: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: color.opacity(opacity), location: 0),
                        .init(color: color.opacity(opacity * 0.72), location: 0.26),
                        .init(color: color.opacity(opacity * 0.22), location: 0.58),
                        .init(color: .clear, location: 0.72)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .blur(radius: 80)
            .drawingGroup(opaque: false, colorMode: .linear)
    }
}

private struct RizzrNoiseOverlay: View {
    var body: some View {
        Canvas { context, size in
            var generator = SeededGenerator(seed: 0x52495A5A52)
            for _ in 0..<Int((size.width * size.height) / 28) {
                let x = CGFloat.random(in: 0...size.width, using: &generator)
                let y = CGFloat.random(in: 0...size.height, using: &generator)
                let alpha = Double.random(in: 0.025...0.11, using: &generator)
                context.fill(Path(CGRect(x: x, y: y, width: 0.7, height: 0.7)), with: .color(.white.opacity(alpha)))
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(RizzrSpacing.lg)
            .background(.ultraThinMaterial, in: cardShape)
            .background(
                LinearGradient(colors: [Color.white.opacity(0.065), Color.white.opacity(0.018)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: cardShape
            )
            .overlay(cardShape.stroke(RizzrColor.glassBorder, lineWidth: 1))
            .overlay(alignment: .top) {
                LinearGradient(colors: [.white.opacity(0.18), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(height: 1)
                    .padding(.horizontal, RizzrRadius.medium)
            }
            .shadow(color: .black.opacity(0.34), radius: 28, x: 0, y: 18)
    }

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: RizzrRadius.large, style: .continuous)
    }
}
