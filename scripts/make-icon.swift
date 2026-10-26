// Native, reproducible app artwork. Run from the repository root.
import AppKit
import Foundation

let output = URL(fileURLWithPath: "build/AppIcon.iconset", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let context = NSGraphicsContext.current!.cgContext
        context.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
        let background = NSBezierPath(roundedRect: NSRect(x: 30, y: 30, width: 964, height: 964), xRadius: 210, yRadius: 210)
        NSGradient(starting: NSColor(calibratedRed: 0.16, green: 0.33, blue: 0.80, alpha: 1),
                   ending: NSColor(calibratedRed: 0.28, green: 0.62, blue: 0.92, alpha: 1))!.draw(in: background, angle: 65)
        for (offset, alpha) in [(0.0, 0.35), (75.0, 0.6), (150.0, 1.0)] {
            NSColor.white.withAlphaComponent(alpha).setFill()
            NSBezierPath(roundedRect: NSRect(x: 200, y: 195 + offset, width: 624, height: 390), xRadius: 42, yRadius: 42).fill()
        }
        NSColor(calibratedRed: 0.12, green: 0.32, blue: 0.64, alpha: 1).setFill()
        let mountain = NSBezierPath()
        mountain.move(to: NSPoint(x: 270, y: 410))
        mountain.line(to: NSPoint(x: 410, y: 580))
        mountain.line(to: NSPoint(x: 520, y: 470))
        mountain.line(to: NSPoint(x: 630, y: 605))
        mountain.line(to: NSPoint(x: 755, y: 410))
        mountain.close(); mountain.fill()
        NSColor(calibratedRed: 0.96, green: 0.70, blue: 0.30, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: 290, y: 610, width: 65, height: 65)).fill()
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(size)x\(size)" + (scale == 2 ? "@2x" : "") + ".png"
        try rep.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
    }
}
