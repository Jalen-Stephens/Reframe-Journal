// Purpose: Reusable liquid glass card container for emphasized and standard surfaces.
import SwiftUI

struct GlassCard<Content: View>: View {
    @Environment(\.notesPalette) private var notesPalette

    let emphasized: Bool
    let padding: CGFloat
    let content: Content

    init(emphasized: Bool = false, padding: CGFloat = AppTheme.cardPadding, @ViewBuilder content: () -> Content) {
        self.emphasized = emphasized
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
        let fill = emphasized ? notesPalette.glassFillEmphasized : notesPalette.glassFill
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: shape)
            .overlay(
                shape
                    .fill(notesPalette.glassHighlight)
                    .opacity(emphasized ? 0.28 : 0.18)
            )
            .overlay(
                shape
                    .stroke(
                        notesPalette.glassBorder,
                        lineWidth: emphasized ? AppTheme.glassStrokeWidthStrong : AppTheme.glassStrokeWidth
                    )
            )
            .shadow(
                color: notesPalette.glassShadow,
                radius: emphasized ? AppTheme.glassShadowRadius * 0.7 : AppTheme.glassShadowRadius * 0.5,
                x: 0,
                y: emphasized ? AppTheme.glassShadowYOffset * 0.6 : AppTheme.glassShadowYOffset * 0.4
            )
    }
}
