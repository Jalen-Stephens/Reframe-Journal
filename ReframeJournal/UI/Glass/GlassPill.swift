// Purpose: Pill-shaped glass surfaces for buttons and chips.
import SwiftUI

struct GlassPill<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let padding: EdgeInsets
    let content: Content

    init(padding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12), @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                .ultraThinMaterial,
                in: Capsule(style: .continuous)
            )
            .overlay(
                Capsule(style: .continuous)
                    .fill(AppTheme.glassHighlightGradient(for: colorScheme))
                    .opacity(0.3)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(AppTheme.glassBorderColor(for: colorScheme), lineWidth: AppTheme.glassStrokeWidth)
            )
            .shadow(
                color: AppTheme.glassShadowColor(for: colorScheme),
                radius: AppTheme.glassShadowRadius * 0.5,
                x: 0,
                y: AppTheme.glassShadowYOffset * 0.4
            )
    }
}

struct GlassPillButton<Label: View>: View {
    let action: () -> Void
    let label: Label

    init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            GlassPill {
                label
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: AppTheme.minTapSize)
    }
}
