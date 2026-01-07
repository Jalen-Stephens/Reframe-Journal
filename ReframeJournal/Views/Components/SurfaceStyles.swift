import SwiftUI

// MARK: - Surface Styles

struct CardSurface: ViewModifier {
    @Environment(\.notesPalette) private var notesPalette

    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            .background(notesPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(notesPalette.separator.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: notesPalette.glassShadow, radius: shadow ? 8 : 0, x: 0, y: shadow ? 3 : 0)
    }
}

struct PillSurface: ViewModifier {
    @Environment(\.notesPalette) private var notesPalette

    let cornerRadius: CGFloat
    let shadow: Bool

    func body(content: Content) -> some View {
        content
            .background(notesPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(notesPalette.separator.opacity(0.6), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: notesPalette.glassShadow, radius: shadow ? 6 : 0, x: 0, y: shadow ? 2 : 0)
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
