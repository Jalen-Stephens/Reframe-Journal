// Purpose: Renders Heroicons outline symbols with consistent sizing and stroke styling.
import SwiftUI

struct AppIconView: View {
    let icon: AppIcon
    let size: CGFloat
    let lineWidth: CGFloat

    init(icon: AppIcon, size: CGFloat = AppTheme.iconSizeMedium, lineWidth: CGFloat = AppTheme.iconLineWidth) {
        self.icon = icon
        self.size = size
        self.lineWidth = lineWidth
    }

    var body: some View {
        GeometryReader { proxy in
            let baseSize: CGFloat = 24
            let target = min(proxy.size.width, proxy.size.height)
            let scale = target / baseSize
            let normalized = normalizedPath(iconView, in: CGRect(x: 0, y: 0, width: baseSize, height: baseSize))
            let offset = (proxy.size.width - target) * 0.5
            normalized
                .applying(CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: offset / scale, y: (proxy.size.height - target) * 0.5 / scale))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .accessibilityHidden(true)
        }
        .frame(width: size, height: size)
    }

    private var iconView: Path {
        switch icon {
        case .plus:
            return HeroIconPlus().path
        case .minus:
            return HeroIconMinus().path
        case .settings:
            return HeroIconCog6Tooth().path
        case .chevronLeft:
            return HeroIconChevronLeft().path
        case .chevronDown:
            return HeroIconChevronDown().path
        case .check:
            return HeroIconCheck().path
        case .sparkles:
            return HeroIconSparkles().path
        case .arrowRight:
            return HeroIconArrowRight().path
        }
    }

    private func normalizedPath(_ path: Path, in rect: CGRect) -> Path {
        let bounds = path.boundingRect
        guard bounds.width > 0, bounds.height > 0 else { return path }
        let dx = rect.midX - bounds.midX
        let dy = rect.midY - bounds.midY
        return path.applying(CGAffineTransform(translationX: dx, y: dy))
    }
}
