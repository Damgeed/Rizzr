import SwiftUI

struct RizzrBackground: View {
    var body: some View {
        ZStack {
            RizzrColor.background.ignoresSafeArea()

            Circle()
                .fill(
                    RadialGradient(
                        colors: [RizzrColor.orbCoral.opacity(0.5), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 210
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -190, y: -330)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [RizzrColor.orbViolet.opacity(0.5), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 245
                    )
                )
                .frame(width: 430, height: 430)
                .blur(radius: 90)
                .offset(x: 190, y: 340)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [RizzrColor.orbCyan.opacity(0.13), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 160
                    )
                )
                .frame(width: 270, height: 270)
                .blur(radius: 80)
                .offset(x: 170, y: 70)
        }
        .overlay(RizzrNoiseOverlay().ignoresSafeArea().opacity(0.12))
        .accessibilityHidden(true)
    }
}

private struct RizzrNoiseOverlay: View {
    var body: some View {
        Canvas { context, size in
            for x in stride(from: 0, through: size.width, by: 3) {
                for y in stride(from: 0, through: size.height, by: 3) where Int(x + y).isMultiple(of: 11) {
                    context.fill(
                        Path(CGRect(x: x, y: y, width: 0.7, height: 0.7)),
                        with: .color(.white.opacity(0.08))
                    )
                }
            }
        }
        .blendMode(.overlay)
        .allowsHitTesting(false)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(RizzrSpacing.lg)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: RizzrRadius.medium, style: .continuous))
            .background(RizzrColor.glassFill, in: RoundedRectangle(cornerRadius: RizzrRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RizzrRadius.medium, style: .continuous)
                    .stroke(RizzrColor.glassBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 30, x: 0, y: 18)
    }
}
