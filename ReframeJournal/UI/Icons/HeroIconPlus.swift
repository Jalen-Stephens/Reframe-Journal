// Purpose: Heroicons outline plus symbol path.
import SwiftUI

struct HeroIconPlus {
    var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 12, y: 4.5))
        path.addLine(to: CGPoint(x: 12, y: 19.5))
        path.move(to: CGPoint(x: 4.5, y: 12))
        path.addLine(to: CGPoint(x: 19.5, y: 12))
        return path
    }
}
