// Purpose: Heroicons outline share path.
import SwiftUI

struct HeroIconShare {
    var path: Path {
        var path = Path()
        path.addRoundedRect(
            in: CGRect(x: 4, y: 10, width: 16, height: 10),
            cornerSize: CGSize(width: 2, height: 2)
        )
        path.move(to: CGPoint(x: 12, y: 4))
        path.addLine(to: CGPoint(x: 12, y: 14))
        path.move(to: CGPoint(x: 8.5, y: 7.5))
        path.addLine(to: CGPoint(x: 12, y: 4))
        path.addLine(to: CGPoint(x: 15.5, y: 7.5))
        return path
    }
}
