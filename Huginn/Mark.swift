import CoreGraphics

/// A single annotation, in image pixel coordinates (origin bottom-left).
enum Mark {
    case rectangle(CGRect)
    case path([CGPoint])
}

enum MarkRenderer {
    static let color = CGColor(srgbRed: 1, green: 0.15, blue: 0.1, alpha: 1)

    static func draw(_ marks: [Mark], in context: CGContext, lineWidth: CGFloat) {
        context.saveGState()
        defer { context.restoreGState() }
        context.setStrokeColor(color)
        context.setLineWidth(lineWidth)
        context.setLineCap(.round)

        for mark in marks {
            switch mark {
            case .rectangle(let rect):
                context.setLineJoin(.miter)
                context.stroke(rect)
            case .path(let points):
                context.setLineJoin(.round)
                context.addPath(smoothPath(through: points))
                context.strokePath()
            }
        }
    }

    /// Quadratic curves through the midpoints between samples, which takes the
    /// jitter out of a mouse- or trackpad-drawn line.
    private static func smoothPath(through points: [CGPoint]) -> CGPath {
        let path = CGMutablePath()
        guard let first = points.first, let last = points.last else { return path }
        path.move(to: first)
        guard points.count > 2 else {
            path.addLine(to: last)
            return path
        }
        for i in 1..<(points.count - 1) {
            let mid = CGPoint(x: (points[i].x + points[i + 1].x) / 2, y: (points[i].y + points[i + 1].y) / 2)
            path.addQuadCurve(to: mid, control: points[i])
        }
        path.addLine(to: last)
        return path
    }
}
