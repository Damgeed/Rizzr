import SwiftUI

struct RizzrBackground: View {
    var body: some View {
        ZStack {
            RizzrColor.background.ignoresSafeArea()

            Circle()
                .fill(RizzrColor.orbCoral.opacity(0.45))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -170, y: -310)

            Circle()
                .fill(RizzrColor.orbViolet.opacity(0.42))
                .frame(width: 380, height: 380)
                .blur(radius: 90)
                .offset(x: 180, y: 320)

            Circle()
                .fill(RizzrColor.orbCyan.opacity(0.22))
                .frame(width: 260, height: 260)
                .blur(radius: 75)
                .offset(x: 80, y: -40)
        }
        .accessibilityHidden(true)
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
            .background(RizzrColor.glassFill, in: RoundedRectangle(cornerRadius: RizzrRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: RizzrRadius.medium, style: .continuous)
                    .stroke(RizzrColor.glassBorder, lineWidth: 1)
            )
    }
}
