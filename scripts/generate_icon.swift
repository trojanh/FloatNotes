import Cocoa

func generateAppIcon() -> NSImage {
    let size = NSSize(width: 1024, height: 1024)
    let image = NSImage(size: size)
    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // 1. Overall Rounded App Squircle / Background
    let squircleRect = CGRect(x: 80, y: 80, width: 864, height: 864)
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: 200, cornerHeight: 200, transform: nil)

    // Vibrant Modern Background Gradient (Deep Indigo to Twilight Violet)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.28, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.22, green: 0.12, blue: 0.38, alpha: 1.0).cgColor
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!

    context.saveGState()
    context.addPath(squirclePath)
    context.clip()
    context.drawLinearGradient(bgGradient, start: CGPoint(x: 80, y: 944), end: CGPoint(x: 944, y: 80), options: [])
    context.restoreGState()

    // Squircle subtle border & soft shadow
    context.saveGState()
    context.setStrokeColor(NSColor.white.withAlphaComponent(0.18).cgColor)
    context.setLineWidth(6)
    context.addPath(squirclePath)
    context.strokePath()
    context.restoreGState()

    // 2. Background floating card (Cyan/Mint tilted slightly)
    context.saveGState()
    context.translateBy(x: 512, y: 512)
    context.rotate(by: -10.0 * .pi / 180.0)
    let backCardRect = CGRect(x: -240, y: -260, width: 480, height: 500)
    let backCardPath = CGPath(roundedRect: backCardRect, cornerWidth: 48, cornerHeight: 48, transform: nil)
    
    // Shadow for back card
    context.setShadow(offset: CGSize(width: 0, height: -20), blur: 30, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    let mintColors = [
        NSColor(calibratedRed: 0.40, green: 0.88, blue: 0.82, alpha: 0.90).cgColor,
        NSColor(calibratedRed: 0.25, green: 0.75, blue: 0.70, alpha: 0.90).cgColor
    ] as CFArray
    let mintGradient = CGGradient(colorsSpace: colorSpace, colors: mintColors, locations: [0.0, 1.0])!
    context.addPath(backCardPath)
    context.clip()
    context.drawLinearGradient(mintGradient, start: CGPoint(x: 0, y: 240), end: CGPoint(x: 0, y: -260), options: [])
    context.restoreGState()

    // 3. Foreground floating card (Vibrant Post-it Yellow tilted +6 degrees)
    context.saveGState()
    context.translateBy(x: 520, y: 490)
    context.rotate(by: 5.0 * .pi / 180.0)
    let frontCardRect = CGRect(x: -240, y: -250, width: 480, height: 500)
    let frontCardPath = CGPath(roundedRect: frontCardRect, cornerWidth: 48, cornerHeight: 48, transform: nil)

    context.setShadow(offset: CGSize(width: 0, height: -28), blur: 40, color: NSColor.black.withAlphaComponent(0.45).cgColor)
    let yellowColors = [
        NSColor(calibratedRed: 1.00, green: 0.94, blue: 0.48, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.98, green: 0.82, blue: 0.28, alpha: 1.0).cgColor
    ] as CFArray
    let yellowGradient = CGGradient(colorsSpace: colorSpace, colors: yellowColors, locations: [0.0, 1.0])!
    context.addPath(frontCardPath)
    context.clip()
    context.drawLinearGradient(yellowGradient, start: CGPoint(x: 0, y: 250), end: CGPoint(x: 0, y: -250), options: [])

    // Decorative note ruled lines
    context.setStrokeColor(NSColor(calibratedRed: 0.35, green: 0.28, blue: 0.12, alpha: 0.22).cgColor)
    context.setLineWidth(14)
    context.setLineCap(.round)

    let lineYPositions: [CGFloat] = [70, 0, -70, -140]
    let lineWidths: [CGFloat] = [320, 360, 280, 220]

    for (y, w) in zip(lineYPositions, lineWidths) {
        context.move(to: CGPoint(x: -180, y: y))
        context.addLine(to: CGPoint(x: -180 + w, y: y))
        context.strokePath()
    }

    // Top status pill badge inside front card ("doing" in electric blue)
    let badgeRect = CGRect(x: -180, y: 155, width: 140, height: 44)
    let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: 22, cornerHeight: 22, transform: nil)
    context.setFillColor(NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.95, alpha: 0.30).cgColor)
    context.addPath(badgePath)
    context.fillPath()
    context.setStrokeColor(NSColor(calibratedRed: 0.18, green: 0.52, blue: 0.95, alpha: 0.80).cgColor)
    context.setLineWidth(3)
    context.addPath(badgePath)
    context.strokePath()

    context.restoreGState()

    // 4. Vibrant 3D Red Pushpin at top center
    context.saveGState()
    context.translateBy(x: 540, y: 770)
    context.setShadow(offset: CGSize(width: 8, height: -18), blur: 24, color: NSColor.black.withAlphaComponent(0.55).cgColor)

    // Pin head (sphere with highlight)
    let pinHeadRect = CGRect(x: -36, y: -36, width: 72, height: 72)
    let pinHeadPath = CGPath(ellipseIn: pinHeadRect, transform: nil)
    let redColors = [
        NSColor(calibratedRed: 1.0, green: 0.35, blue: 0.35, alpha: 1.0).cgColor,
        NSColor(calibratedRed: 0.85, green: 0.08, blue: 0.12, alpha: 1.0).cgColor
    ] as CFArray
    let redGradient = CGGradient(colorsSpace: colorSpace, colors: redColors, locations: [0.0, 1.0])!
    context.addPath(pinHeadPath)
    context.clip()
    context.drawRadialGradient(redGradient, startCenter: CGPoint(x: -10, y: 10), startRadius: 4, endCenter: CGPoint(x: 0, y: 0), endRadius: 36, options: [])
    context.restoreGState()

    image.unlockFocus()
    return image
}

let image = generateAppIcon()
if let tiffData = image.tiffRepresentation,
   let rep = NSBitmapImageRep(data: tiffData),
   let pngData = rep.representation(using: .png, properties: [:]) {
    let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon1024.png"
    try? pngData.write(to: URL(fileURLWithPath: outputPath))
    print("Generated 1024x1024 icon at \(outputPath)")
}
