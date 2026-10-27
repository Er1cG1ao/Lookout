import AppKit

let folder = CommandLine.arguments[1]
try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
for side in [16, 32, 64, 128, 256, 512, 1024] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: side * 4, bitsPerPixel: 32)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let size = CGFloat(side)
    let shape = NSBezierPath(roundedRect: NSRect(x: size * 0.035, y: size * 0.035, width: size * 0.93, height: size * 0.93), xRadius: size * 0.205, yRadius: size * 0.205)
    NSGradient(starting: NSColor(calibratedRed: 0.31, green: 0.61, blue: 1, alpha: 1), ending: NSColor(calibratedRed: 0.12, green: 0.31, blue: 0.84, alpha: 1))!.draw(in: shape, angle: -70)
    let eye = NSBezierPath()
    eye.move(to: NSPoint(x: size * 0.18, y: size * 0.5))
    eye.curve(to: NSPoint(x: size * 0.82, y: size * 0.5), controlPoint1: NSPoint(x: size * 0.36, y: size * 0.79), controlPoint2: NSPoint(x: size * 0.64, y: size * 0.79))
    eye.curve(to: NSPoint(x: size * 0.18, y: size * 0.5), controlPoint1: NSPoint(x: size * 0.64, y: size * 0.21), controlPoint2: NSPoint(x: size * 0.36, y: size * 0.21))
    eye.close()
    NSColor.white.setFill(); eye.fill()
    NSColor(calibratedRed: 0.20, green: 0.44, blue: 0.93, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: size * 0.38, y: size * 0.38, width: size * 0.24, height: size * 0.24)).fill()
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: size * 0.48, y: size * 0.52, width: size * 0.065, height: size * 0.065)).fill()
    NSGraphicsContext.restoreGraphicsState()
    let png = bitmap.representation(using: .png, properties: [:])!
    let names: [String]
    switch side {
    case 16: names = ["icon_16x16.png"]
    case 32: names = ["icon_16x16@2x.png", "icon_32x32.png"]
    case 64: names = ["icon_32x32@2x.png"]
    case 128: names = ["icon_128x128.png"]
    case 256: names = ["icon_128x128@2x.png", "icon_256x256.png"]
    case 512: names = ["icon_256x256@2x.png", "icon_512x512.png"]
    default: names = ["icon_512x512@2x.png"]
    }
    for name in names { try png.write(to: URL(fileURLWithPath: folder).appendingPathComponent(name)) }
}
