import SwiftUI

// MARK: - Surface Styles

struct CardSurface: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            .background(themeManager.theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadow ? 10 : 0, x: 0, y: shadow ? 4 : 0)
    }

    private var borderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.black.opacity(0.06)
        }
    }

    private var shadowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.35)
        default:
            return Color.black.opacity(0.08)
        }
    }
}

struct PillSurface: ViewModifier {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            .background(themeManager.theme.card)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: shadowColor, radius: shadow ? 6 : 0, x: 0, y: shadow ? 3 : 0)
    }

    private var borderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.08)
        default:
            return Color.black.opacity(0.06)
        }
    }

    private var shadowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.3)
        default:
            return Color.black.opacity(0.06)
        }
    }
}

extension View {
    func cardSurface(cornerRadius: CGFloat = 14, shadow: Bool = true) -> some View {
        modifier(CardSurface(cornerRadius: cornerRadius, shadow: shadow))
    }

    func pillSurface(cornerRadius: CGFloat = 16, shadow: Bool = false) -> some View {
        modifier(PillSurface(cornerRadius: cornerRadius, shadow: shadow))
    }
}
