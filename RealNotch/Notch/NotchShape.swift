import SwiftUI

/// The notch outline: square top corners (flush with the screen edge),
/// rounded bottom corners flaring outward like the hardware notch.
struct NotchShape: Shape {
    var bottomRadius: CGFloat

    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(bottomRadius, rect.height / 2, rect.width / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX - r, y: rect.minY))
        // top-left flare into the notch
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + r),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + r, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - r),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + r))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX + r, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        p.closeSubpath()
        return p
    }
}
