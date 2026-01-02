// Purpose: Heroicons-inspired sparkles outline path.
import SwiftUI

struct HeroIconSparkles {
    var path: Path {
        var path = Path()
        addSparkle(to: &path, center: CGPoint(x: 7, y: 16), size: 3.5)
        addSparkle(to: &path, center: CGPoint(x: 16.5, y: 7.5), size: 4.5)
        addSparkle(to: &path, center: CGPoint(x: 18, y: 17), size: 2.5)
        return path
    }

    private func addSparkle(to path: inout Path, center: CGPoint, size: CGFloat) {
        let half = size / 2
        path.move(to: CGPoint(x: center.x, y: center.y - size))
        path.addLine(to: CGPoint(x: center.x, y: center.y - half))
        path.move(to: CGPoint(x: center.x, y: center.y + half))
        path.addLine(to: CGPoint(x: center.x, y: center.y + size))
        path.move(to: CGPoint(x: center.x - size, y: center.y))
        path.addLine(to: CGPoint(x: center.x - half, y: center.y))
        path.move(to: CGPoint(x: center.x + half, y: center.y))
        path.addLine(to: CGPoint(x: center.x + size, y: center.y))
        path.move(to: CGPoint(x: center.x - size * 0.7, y: center.y - size * 0.7))
        path.addLine(to: CGPoint(x: center.x - half, y: center.y - half))
        path.move(to: CGPoint(x: center.x + half, y: center.y + half))
        path.addLine(to: CGPoint(x: center.x + size * 0.7, y: center.y + size * 0.7))
        path.move(to: CGPoint(x: center.x - size * 0.7, y: center.y + size * 0.7))
        path.addLine(to: CGPoint(x: center.x - half, y: center.y + half))
        path.move(to: CGPoint(x: center.x + half, y: center.y - half))
        path.addLine(to: CGPoint(x: center.x + size * 0.7, y: center.y - size * 0.7))
    }
}
