// Purpose: Centralized theme constants for glass UI sizing and styling.
import SwiftUI

enum AppTheme {
    static let cardCornerRadius: CGFloat = 18
    static let cardCornerRadiusCompact: CGFloat = 14
    static let pillCornerRadius: CGFloat = 999
    static let cardPadding: CGFloat = 16
    static let cardPaddingCompact: CGFloat = 12
    static let glassStrokeWidth: CGFloat = 0.8
    static let glassStrokeWidthStrong: CGFloat = 1.3
    static let glassShadowRadius: CGFloat = 10
    static let glassShadowYOffset: CGFloat = 6
    static let iconLineWidth: CGFloat = 1.5
    static let iconSizeSmall: CGFloat = 18
    static let iconSizeMedium: CGFloat = 20
    static let iconSizeLarge: CGFloat = 22
    static let iconButtonSize: CGFloat = 40
    static let minTapSize: CGFloat = 44

    static func glassHighlightGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let top = Color.white.opacity(colorScheme == .dark ? 0.16 : 0.35)
        let mid = Color.white.opacity(colorScheme == .dark ? 0.08 : 0.2)
        let bottom = Color.white.opacity(colorScheme == .dark ? 0.04 : 0.12)
        return LinearGradient(colors: [top, mid, bottom], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func glassBorderColor(for colorScheme: ColorScheme) -> Color {
        Color.white.opacity(colorScheme == .dark ? 0.18 : 0.28)
    }

    static func glassShadowColor(for colorScheme: ColorScheme) -> Color {
        Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12)
    }
}
