// Purpose: Heroicons outline minus path.
import SwiftUI

struct HeroIconMinus {
    var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 5, y: 12))
        path.addLine(to: CGPoint(x: 19, y: 12))
        return path
    }
}
