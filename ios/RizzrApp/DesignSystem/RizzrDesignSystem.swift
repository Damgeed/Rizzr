import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum RizzrColor {
    static let background = Color(hex: 0x030305)
    static let orbCoral = Color(hex: 0xFF2D6D)
    static let orbViolet = Color(hex: 0x6E22FF)
    static let orbCyan = Color(hex: 0x00D4FF)
    static let textPrimary = Color.white
    static let textMuted = Color(hex: 0xA1A1AA)
    static let glassFill = Color.white.opacity(0.03)
    static let glassHover = Color.white.opacity(0.08)
    static let glassBorder = Color.white.opacity(0.08)
    static let navGlass = Color(hex: 0x08080E).opacity(0.34)
}

enum RizzrRadius {
    static let small: CGFloat = 12
    static let medium: CGFloat = 20
    static let large: CGFloat = 28
    static let phone: CGFloat = 46
    static let pill: CGFloat = 999
}

enum RizzrSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum RizzrTypography {
    static let logo = outfit(size: 34, weight: .heavy)
    static let hero = outfit(size: 39, weight: .bold)
    static let display = outfit(size: 32, weight: .bold)
    static let title = outfit(size: 24, weight: .bold)
    static let body = outfit(size: 16, weight: .regular)
    static let bodyStrong = outfit(size: 16, weight: .semibold)
    static let caption = outfit(size: 12, weight: .semibold)

    static func outfit(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("Outfit", fixedSize: size).weight(weight)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
