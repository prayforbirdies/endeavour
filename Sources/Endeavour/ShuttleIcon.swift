import AppKit

/// A top-view Space Shuttle orbiter silhouette — a nod to Endeavour.
/// Defined once as a normalized outline (0...1, nose at top) and reused for the
/// crisp, vector menu-bar template image at any size.
enum ShuttleIcon {

    /// Right half of the symmetric outline, traced nose -> aft, y measured
    /// downward from the top. The left half is mirrored at draw time.
    static let rightHalf: [CGPoint] = [
        CGPoint(x: 0.500, y: 0.050), // nose tip
        CGPoint(x: 0.540, y: 0.110), // nose shoulder
        CGPoint(x: 0.552, y: 0.340), // forward fuselage
        CGPoint(x: 0.552, y: 0.460), // wing root (leading edge start)
        CGPoint(x: 0.930, y: 0.720), // right wingtip (leading edge)
        CGPoint(x: 0.930, y: 0.790), // wingtip trailing corner
        CGPoint(x: 0.630, y: 0.800), // wing trailing root
        CGPoint(x: 0.630, y: 0.900), // aft fuselage / OMS pod
        CGPoint(x: 0.552, y: 0.930), // tail base
        CGPoint(x: 0.500, y: 0.930), // aft center
    ]

    /// Build the filled silhouette path inside `rect` (AppKit y-up coordinates).
    static func path(in rect: CGRect) -> NSBezierPath {
        func pt(_ n: CGPoint) -> NSPoint {
            NSPoint(x: rect.minX + n.x * rect.width,
                    y: rect.minY + (1.0 - n.y) * rect.height)
        }

        let path = NSBezierPath()
        path.move(to: pt(rightHalf[0]))
        for p in rightHalf.dropFirst() { path.line(to: pt(p)) }
        // Mirror back up the left side (skip the shared aft-center endpoint).
        for p in rightHalf.dropLast().reversed() {
            path.line(to: pt(CGPoint(x: 1.0 - p.x, y: p.y)))
        }
        path.close()
        return path
    }

    /// A monochrome template image for the menu bar (tints itself for light/dark).
    static func menuBarImage(pointSize: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize),
                            flipped: false) { rect in
            NSColor.black.setFill()
            let inset = rect.insetBy(dx: rect.width * 0.06, dy: rect.height * 0.02)
            path(in: inset).fill()
            return true
        }
        image.isTemplate = true
        return image
    }
}
