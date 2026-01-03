// Purpose: Heroicons outline ellipsis-horizontal path.
import SwiftUI

struct HeroIconEllipsis {
    var path: Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: 5.5, y: 11, width: 2, height: 2))
        path.addEllipse(in: CGRect(x: 11, y: 11, width: 2, height: 2))
        path.addEllipse(in: CGRect(x: 16.5, y: 11, width: 2, height: 2))
        return path
    }
}
