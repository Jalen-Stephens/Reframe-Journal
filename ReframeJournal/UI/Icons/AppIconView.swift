// Purpose: Renders Heroicons outline symbols with consistent sizing and stroke styling.
import SwiftUI

// MARK: - Local Heroicons paths

private struct HeroIconCircle {
    var path: Path {
        Path { path in
            path.addEllipse(in: CGRect(x: 3.0, y: 3.0, width: 18.0, height: 18.0))
        }
    }
}

private struct HeroIconCheckCircle {
    var path: Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 3.0, y: 3.0, width: 18.0, height: 18.0))
        path.move(to: CGPoint(x: 8.0, y: 12.5))
        path.addLine(to: CGPoint(x: 11.0, y: 15.0))
        path.addLine(to: CGPoint(x: 16.0, y: 9.5))
        return path
    }
}

struct AppIconView: View {
    @Environment(\.notesPalette) private var notesPalette

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
        .foregroundStyle(notesPalette.icon)
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
        case .chevronRight:
            return HeroIconChevronRight().path
        case .check:
            return HeroIconCheck().path
        case .checkCircle:
            return HeroIconCheckCircle().path
        case .circle:
            return HeroIconCircle().path
        case .sparkles:
            return HeroIconSparkles().path
        case .arrowRight:
            return HeroIconArrowRight().path
        case .ellipsis:
            return HeroIconEllipsis().path
        case .share:
            return HeroIconShare().path
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
