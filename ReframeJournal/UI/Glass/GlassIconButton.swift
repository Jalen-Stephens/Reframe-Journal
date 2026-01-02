// Purpose: Circular glass icon button with consistent hit area and styling.
import SwiftUI

struct GlassIconButton: View {
    @Environment(\.colorScheme) private var colorScheme

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
        Button(action: action) {
            AppIconView(icon: icon, size: size)
                .foregroundStyle(.primary)
                .frame(width: AppTheme.iconButtonSize, height: AppTheme.iconButtonSize)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .background(
            .ultraThinMaterial,
            in: Circle()
        )
        .overlay(
            Circle()
                .fill(AppTheme.glassHighlightGradient(for: colorScheme))
                .opacity(0.3)
        )
        .overlay(
            Circle()
                .stroke(AppTheme.glassBorderColor(for: colorScheme), lineWidth: AppTheme.glassStrokeWidth)
        )
        .shadow(
            color: AppTheme.glassShadowColor(for: colorScheme),
            radius: AppTheme.glassShadowRadius * 0.5,
            x: 0,
            y: AppTheme.glassShadowYOffset * 0.4
        )
        .frame(minWidth: AppTheme.minTapSize, minHeight: AppTheme.minTapSize)
        .accessibilityLabel(accessibilityLabel)
    }
}
