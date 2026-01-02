// Purpose: Heroicons outline cog-6-tooth path derived from provided SVG.
import SwiftUI

struct HeroIconCog6Tooth {
    var path: Path {
        var path = Path()
        var current = CGPoint.zero

        func move(_ x: CGFloat, _ y: CGFloat) {
            current = CGPoint(x: x, y: y)
            path.move(to: current)
        }

        func relLine(_ dx: CGFloat, _ dy: CGFloat) {
            current = CGPoint(x: current.x + dx, y: current.y + dy)
            path.addLine(to: current)
        }

        func relH(_ dx: CGFloat) {
            relLine(dx, 0)
        }

        func relV(_ dy: CGFloat) {
            relLine(0, dy)
        }

        func relCurve(_ dx1: CGFloat, _ dy1: CGFloat, _ dx2: CGFloat, _ dy2: CGFloat, _ dx: CGFloat, _ dy: CGFloat) {
            let control1 = CGPoint(x: current.x + dx1, y: current.y + dy1)
            let control2 = CGPoint(x: current.x + dx2, y: current.y + dy2)
            current = CGPoint(x: current.x + dx, y: current.y + dy)
            path.addCurve(to: current, control1: control1, control2: control2)
        }

        move(10.343, 3.94)
        relCurve(0.09, -0.542, 0.56, -0.94, 1.11, -0.94)
        relH(1.093)
        relCurve(0.55, 0, 1.02, 0.398, 1.11, 0.94)
        relLine(0.149, 0.894)
        relCurve(0.07, 0.424, 0.384, 0.764, 0.78, 0.93)
        relCurve(0.398, 0.164, 0.855, 0.142, 1.205, -0.108)
        relLine(0.737, -0.527)
        relLine(1.45, 0.12)
        relLine(0.773, 0.774)
        relCurve(0.39, 0.389, 0.44, 1.002, 0.12, 1.45)
        relLine(-0.527, 0.737)
        relCurve(-0.25, 0.35, -0.272, 0.806, -0.107, 1.204)
        relCurve(0.165, 0.397, 0.505, 0.71, 0.93, 0.78)
        relLine(0.893, 0.15)
        relCurve(0.543, 0.09, 0.94, 0.559, 0.94, 1.109)
        relV(1.094)
        relCurve(0, 0.55, -0.397, 1.02, -0.94, 1.11)
        relLine(-0.894, 0.149)
        relCurve(-0.424, 0.07, -0.764, 0.383, -0.929, 0.78)
        relCurve(-0.165, 0.398, -0.143, 0.854, 0.107, 1.204)
        relLine(0.527, 0.738)
        relCurve(0.32, 0.447, 0.269, 1.06, -0.12, 1.45)
        relLine(-0.774, 0.773)
        relLine(-1.449, 0.12)
        relLine(-0.738, -0.527)
        relCurve(-0.35, -0.25, -0.806, -0.272, -1.203, -0.107)
        relCurve(-0.398, 0.165, -0.71, 0.505, -0.781, 0.929)
        relLine(-0.149, 0.894)
        relCurve(-0.09, 0.542, -0.56, 0.94, -1.11, 0.94)
        relH(-1.094)
        relCurve(-0.55, 0, -1.019, -0.398, -1.11, -0.94)
        relLine(-0.148, -0.894)
        relCurve(-0.071, -0.424, -0.384, -0.764, -0.781, -0.93)
        relCurve(-0.398, -0.164, -0.854, -0.142, -1.204, 0.108)
        relLine(-0.738, 0.527)
        relCurve(-0.447, 0.32, -1.06, 0.269, -1.45, -0.12)
        relLine(-0.773, -0.774)
        relLine(-0.12, -1.45)
        relLine(0.527, -0.737)
        relCurve(0.25, -0.35, 0.272, -0.806, 0.108, -1.204)
        relCurve(-0.165, -0.397, -0.506, -0.71, -0.93, -0.78)
        relLine(-0.894, -0.15)
        relCurve(-0.542, -0.09, -0.94, -0.56, -0.94, -1.109)
        relV(-1.094)
        relCurve(0, -0.55, 0.398, -1.02, 0.94, -1.11)
        relLine(0.894, -0.149)
        relCurve(0.424, -0.07, 0.765, -0.383, 0.93, -0.78)
        relCurve(0.165, -0.398, 0.143, -0.854, -0.108, -1.204)
        relLine(-0.526, -0.738)
        relLine(0.12, -1.45)
        relLine(0.773, -0.773)
        relLine(1.45, -0.12)
        relLine(0.737, 0.527)
        relCurve(0.35, 0.25, 0.807, 0.272, 1.204, 0.107)
        relCurve(0.397, -0.165, 0.71, -0.505, 0.78, -0.929)
        relLine(0.15, -0.894)
        path.closeSubpath()

        path.addEllipse(in: CGRect(x: 9, y: 9, width: 6, height: 6))

        return path
    }
}
