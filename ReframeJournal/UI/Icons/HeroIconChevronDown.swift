// Purpose: Heroicons outline chevron-down path.
import SwiftUI

struct HeroIconChevronDown {
    var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 6, y: 9))
        path.addLine(to: CGPoint(x: 12, y: 15))
        path.addLine(to: CGPoint(x: 18, y: 9))
        return path
    }
}
