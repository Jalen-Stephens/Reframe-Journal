// Purpose: Circular glass icon button with consistent hit area and styling.
import SwiftUI

struct GlassIconButton: View {
    @Environment(\.notesPalette) private var notesPalette

    let icon: AppIcon
    let size: CGFloat
    let accessibilityLabel: String
    let action: () -> Void

    init(icon: AppIcon, size: CGFloat = AppTheme.iconSizeMedium, accessibilityLabel: String, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    var body: some View {
        let shape = Circle()
        Button(action: action) {
            AppIconView(icon: icon, size: size)
                .foregroundStyle(notesPalette.icon)
                .frame(width: AppTheme.iconButtonSize, height: AppTheme.iconButtonSize)
                .contentShape(shape)
        }
        .buttonStyle(.plain)
        .background(
            notesPalette.glassFill,
            in: shape
        )
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
        .frame(minWidth: AppTheme.minTapSize, minHeight: AppTheme.minTapSize)
        .accessibilityLabel(accessibilityLabel)
    }
}
