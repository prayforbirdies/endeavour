#!/usr/bin/env swift
//
// Generates Resources/AppIcon.icns for Endeavour: a white Space Shuttle orbiter
// on a deep-space gradient squircle. Run from the repo root:
//
//     swift Scripts/make-icon.swift
//
import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Same normalized orbiter outline as Sources/Endeavour/ShuttleIcon.swift.
let rightHalf: [CGPoint] = [
    CGPoint(x: 0.500, y: 0.050),
    CGPoint(x: 0.540, y: 0.110),
    CGPoint(x: 0.552, y: 0.340),
    CGPoint(x: 0.552, y: 0.460),
    CGPoint(x: 0.930, y: 0.720),
    CGPoint(x: 0.930, y: 0.790),
    CGPoint(x: 0.630, y: 0.800),
    CGPoint(x: 0.630, y: 0.900),
    CGPoint(x: 0.552, y: 0.930),
    CGPoint(x: 0.500, y: 0.930),
]

// Deterministic star field (x, y, radiusFraction) in normalized coords.
let stars: [(CGFloat, CGFloat, CGFloat)] = [
    (0.16, 0.20, 0.012), (0.82, 0.16, 0.010), (0.28, 0.78, 0.009),
    (0.74, 0.72, 0.013), (0.20, 0.52, 0.008), (0.88, 0.46, 0.009),
    (0.12, 0.84, 0.007), (0.66, 0.26, 0.007), (0.36, 0.14, 0.008),
    (0.90, 0.82, 0.008), (0.10, 0.40, 0.006),
]

func shuttlePath(in rect: CGRect) -> CGPath {
    func pt(_ n: CGPoint) -> CGPoint {
        CGPoint(x: rect.minX + n.x * rect.width,
                y: rect.minY + (1.0 - n.y) * rect.height) // CG origin is bottom-left
    }
    let path = CGMutablePath()
    path.move(to: pt(rightHalf[0]))
    for p in rightHalf.dropFirst() { path.addLine(to: pt(p)) }
    for p in rightHalf.dropLast().reversed() {
        path.addLine(to: pt(CGPoint(x: 1.0 - p.x, y: p.y)))
    }
    path.closeSubpath()
    return path
}

func renderIcon(size: CGFloat) -> CGImage {
    let px = Int(size)
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(data: nil, width: px, height: px, bitsPerComponent: 8,
                        bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

    // Squircle clip (Apple icon corner radius ≈ 0.2237 * size).
    let inset = size * 0.06
    let rect = CGRect(x: inset, y: inset, width: size - 2 * inset, height: size - 2 * inset)
    let corner = rect.width * 0.2237
    let squircle = CGPath(roundedRect: rect, cornerWidth: corner, cornerHeight: corner, transform: nil)
    ctx.addPath(squircle)
    ctx.clip()

    // Diagonal space gradient.
    let colors = [
        CGColor(red: 0.28, green: 0.24, blue: 0.62, alpha: 1.0), // indigo
        CGColor(red: 0.06, green: 0.07, blue: 0.18, alpha: 1.0), // near-black navy
    ] as CFArray
    let gradient = CGGradient(colorsSpace: cs, colors: colors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0),
                           options: [])

    // Stars.
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
    for (sx, sy, sr) in stars {
        let r = sr * size
        let c = CGPoint(x: sx * size, y: (1 - sy) * size)
        ctx.fillEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r))
    }

    // Centered, padded orbiter with a soft glow.
    let pad = rect.insetBy(dx: rect.width * 0.17, dy: rect.height * 0.17)
    let orbiter = shuttlePath(in: pad)
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: size * 0.028,
                  color: CGColor(red: 0.55, green: 0.78, blue: 1.0, alpha: 0.7))
    ctx.addPath(orbiter)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// Build the .iconset and convert with iconutil.
let fm = FileManager.default
let iconset = URL(fileURLWithPath: "build/AppIcon.iconset")
try? fm.removeItem(at: iconset)
try! fm.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(String, CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, size) in variants {
    writePNG(renderIcon(size: size), to: iconset.appendingPathComponent(name))
}

try! fm.createDirectory(atPath: "Resources", withIntermediateDirectories: true)
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try! task.run()
task.waitUntilExit()
print(task.terminationStatus == 0 ? "Wrote Resources/AppIcon.icns" : "iconutil failed")
