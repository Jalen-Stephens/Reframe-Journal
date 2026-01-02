// Purpose: Heroicons outline arrow-right path.
import SwiftUI

struct HeroIconArrowRight {
    var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 3, y: 12))
        path.addLine(to: CGPoint(x: 21, y: 12))
        path.move(to: CGPoint(x: 13.5, y: 4.5))
        path.addLine(to: CGPoint(x: 21, y: 12))
        path.addLine(to: CGPoint(x: 13.5, y: 19.5))
        return path
    }
}
