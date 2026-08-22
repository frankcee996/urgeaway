import SwiftUI

/// Design tokens ported 1:1 from `www/css/styles.css`'s `:root` custom
/// properties, so the native app reads as the same product, not a
/// re-skin. Dark navy / cyan / soft-green palette per the product brief.
enum Theme {
    // Backgrounds
    static let bg0 = Color(hex: 0x060B14) // deepest background
    static let bg1 = Color(hex: 0x0C1626) // app background
    static let bg2 = Color(hex: 0x121E33) // card surface
    static let bg3 = Color(hex: 0x1A2B45) // raised surface / pressed

    static let line = Color(hex: 0x94B2D2).opacity(0.14)

    // Accents
    static let cyan = Color(hex: 0x34E0D6)
    static let cyanDim = Color(hex: 0x1FA89F)
    static let cyanGlow = Color(hex: 0x34E0D6).opacity(0.35)
    static let green = Color(hex: 0x8BE3A8)
    static let greenDim = Color(hex: 0x4FB87A)
    static let amber = Color(hex: 0xF2C572)
    /// Used sparingly — echoes the "urge" wave in the mark.
    static let coral = Color(hex: 0xEF8B6F)

    // Text
    static let text0 = Color(hex: 0xF4F9FB)
    static let text1 = Color(hex: 0xC3D3E4)
    static let text2 = Color(hex: 0x7F93AC)
    static let text3 = Color(hex: 0x56657C)

    // Radii
    static let radiusS: CGFloat = 12
    static let radiusM: CGFloat = 18
    static let radiusL: CGFloat = 26
    static let radiusFull: CGFloat = 999

    // Spacing
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 24
    static let space6: CGFloat = 32

    static func displayFont(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func bodyFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

/// Primary gradient CTA button — mirrors `.btn.btn-primary.btn-gradient`.
struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.displayFont(15, weight: .heavy))
            .foregroundColor(Theme.bg0)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [Theme.cyan, Theme.green], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusFull, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GhostButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.bodyFont(14, weight: .semibold))
            .foregroundColor(Theme.text1)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusFull, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.space4)
            .background(Theme.bg2)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusM, style: .continuous)
                    .stroke(Theme.line, lineWidth: 1)
            )
    }
}
extension View {
    func cardBackground() -> some View { modifier(CardBackground()) }
}
