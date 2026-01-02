// Purpose: Heroicons outline chevron-left path.
import SwiftUI

struct HeroIconChevronLeft {
    var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 15.75, y: 19.5))
        path.addLine(to: CGPoint(x: 8.25, y: 12))
        path.addLine(to: CGPoint(x: 15.75, y: 4.5))
        return path
    }
}
