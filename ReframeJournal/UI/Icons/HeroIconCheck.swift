// Purpose: Heroicons outline check path.
import SwiftUI

struct HeroIconCheck {
    var path: Path {
        var path = Path()
        path.move(to: CGPoint(x: 4.5, y: 12.75))
        path.addLine(to: CGPoint(x: 10.5, y: 18.75))
        path.addLine(to: CGPoint(x: 19.5, y: 5.25))
        return path
    }
}
