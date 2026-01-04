// Purpose: Pill-shaped glass surfaces for buttons and chips.
import SwiftUI

struct GlassPill<Content: View>: View {
    @Environment(\.notesPalette) private var notesPalette

    let padding: EdgeInsets
    let content: Content

    init(padding: EdgeInsets = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12), @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let shape = Capsule(style: .continuous)
        content
            .padding(padding)
            .background(notesPalette.glassFill, in: shape)
            .overlay(
                shape
                    .fill(notesPalette.glassHighlight)
                    .opacity(0.18)
            )
            .overlay(
                shape
                    .stroke(notesPalette.glassBorder, lineWidth: AppTheme.glassStrokeWidth)
            )
            .shadow(
                color: notesPalette.glassShadow,
                radius: AppTheme.glassShadowRadius * 0.35,
                x: 0,
                y: AppTheme.glassShadowYOffset * 0.3
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
