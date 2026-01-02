// Purpose: Reusable liquid glass card container for emphasized and standard surfaces.
import SwiftUI

struct GlassCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let emphasized: Bool
    let padding: CGFloat
    let content: Content

    init(emphasized: Bool = false, padding: CGFloat = AppTheme.cardPadding, @ViewBuilder content: () -> Content) {
        self.emphasized = emphasized
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .fill(AppTheme.glassHighlightGradient(for: colorScheme))
                    .opacity(emphasized ? 0.45 : 0.28)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius, style: .continuous)
                    .stroke(
                        AppTheme.glassBorderColor(for: colorScheme),
                        lineWidth: emphasized ? AppTheme.glassStrokeWidthStrong : AppTheme.glassStrokeWidth
                    )
            )
            .shadow(
                color: AppTheme.glassShadowColor(for: colorScheme),
                radius: emphasized ? AppTheme.glassShadowRadius : AppTheme.glassShadowRadius * 0.6,
                x: 0,
                y: emphasized ? AppTheme.glassShadowYOffset : AppTheme.glassShadowYOffset * 0.6
            )
    }
}
