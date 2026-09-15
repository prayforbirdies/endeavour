import AppKit

/// An Imperial Lambda-class shuttle silhouette (front view, wings deployed):
/// a tall central fin with two wings splayed down and outward. Built from a few
/// overlapping polygons unioned via non-zero winding, so it stays crisp at any
/// size for the menu-bar template image.
enum ShuttleIcon {

    // Normalized parts (0...1, y measured downward from the top).
    static let body: [CGPoint] = [
        CGPoint(x: 0.430, y: 0.440),
        CGPoint(x: 0.570, y: 0.440),
        CGPoint(x: 0.600, y: 0.560),
        CGPoint(x: 0.515, y: 0.730),
        CGPoint(x: 0.485, y: 0.730),
        CGPoint(x: 0.400, y: 0.560),
    ]

    static let topWing: [CGPoint] = [
        CGPoint(x: 0.474, y: 0.050),
        CGPoint(x: 0.526, y: 0.050),
        CGPoint(x: 0.560, y: 0.480),
        CGPoint(x: 0.440, y: 0.480),
    ]

    static let leftWing: [CGPoint] = [
        CGPoint(x: 0.470, y: 0.485), // inner top (attaches high on body)
        CGPoint(x: 0.520, y: 0.665), // inner bottom (attaches low on body)
        CGPoint(x: 0.150, y: 0.950), // tip trailing
        CGPoint(x: 0.085, y: 0.895), // tip leading
    ]

    static var rightWing: [CGPoint] {
        leftWing.map { CGPoint(x: 1.0 - $0.x, y: $0.y) }
    }

    static var parts: [[CGPoint]] { [body, topWing, leftWing, rightWing] }

    /// Build the filled silhouette inside `rect` (AppKit y-up coordinates).
    static func path(in rect: CGRect) -> NSBezierPath {
        func pt(_ n: CGPoint) -> NSPoint {
            NSPoint(x: rect.minX + n.x * rect.width,
                    y: rect.minY + (1.0 - n.y) * rect.height)
        }
        let path = NSBezierPath()
        for poly in parts {
            let sub = NSBezierPath()
            for (i, n) in poly.enumerated() {
                if i == 0 { sub.move(to: pt(n)) } else { sub.line(to: pt(n)) }
            }
            sub.close()
            path.append(sub)
        }
        path.windingRule = .nonzero
        return path
    }

    /// A monochrome template image for the menu bar (tints itself for light/dark).
    static func menuBarImage(pointSize: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize),
                            flipped: false) { rect in
            NSColor.black.setFill()
            let inset = rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.02)
            path(in: inset).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
