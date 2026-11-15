import Foundation
import AppKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

// This script synthesizes a smooth animated demo showcasing:
// 1. Floating Sticky Note with Apple Glass UI & Clickable Checklist
// 2. Multi-AI Dispatch menu (Gemini, ChatGPT, Claude, Perplexity)
// 3. View All Notes grid & dynamic search/filtering
// 4. Compact 300x150 sizing & Multi-column Stacking

func createDemoMedia() {
    print("[DemoGenerator] Synthesizing video and GIF demo...")
    let outputDir = "/Users/rajantiwari/Desktop/projects/FloatingNotes-feature-worktree/docs/assets"
    try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

    let width: Int = 800
    let height: Int = 500
    let mp4URL = URL(fileURLWithPath: "\(outputDir)/demo.mp4")
    let gifURL = URL(fileURLWithPath: "\(outputDir)/demo.gif")

    try? FileManager.default.removeItem(at: mp4URL)
    try? FileManager.default.removeItem(at: gifURL)

    // Generate high-resolution scenario frames
    var frames: [NSImage] = []

    let scenarios = [
        ("FloatNotes - Apple Glass Sticky Notes", "• Translucent frosted glass UI with specular rims\n• Stays across macOS Spaces & Fullscreen Apps\n• Status indicator (doing, todo, done) in Menu Bar"),
        ("Interactive Checklists & Smart Actions", "☑ Review PR #3 & Merge Conflicts\n☑ Compact Rectangle Size (300 x 150)\n☐ Deploy Release v1.0.0 to GitHub\n☐ Add Apple Calendar & Reminders"),
        ("Multi-AI Dispatch in 1 Click", "Dispatches note content directly to:\n• Google Gemini\n• OpenAI ChatGPT\n• Anthropic Claude\n• Perplexity AI"),
        ("View All Notes Management & Stacking", "• Search notes, checklists & code instantly\n• Unpin All or Stack Pinned in clean columns\n• Real-time size presets (Compact 300x150)")
    ]

    for (title, text) in scenarios {
        for step in 0..<3 {
            let img = renderDemoFrame(width: width, height: height, title: title, bodyText: text, animStep: step)
            frames.append(img)
        }
    }

    // 1. Export Animated GIF
    print("[DemoGenerator] Exporting animated GIF...")
    if let destination = CGImageDestinationCreateWithURL(gifURL as CFURL, UTType.gif.identifier as CFString, frames.count, nil) {
        let frameProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.2]]
        let gifProperties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        for frame in frames {
            if let cgImage = frame.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
            }
        }
        CGImageDestinationFinalize(destination)
        print("[DemoGenerator] Successfully generated GIF: \(gifURL.path)")
    }

    // 2. Export MP4 Video using AVAssetWriter
    print("[DemoGenerator] Exporting MP4 video...")
    exportMP4(frames: frames, outputURL: mp4URL, width: width, height: height)
}

func renderDemoFrame(width: Int, height: Int, title: String, bodyText: String, animStep: Int) -> NSImage {
    let size = NSSize(width: width, height: height)
    let image = NSImage(size: size)
    image.lockFocus()

    let w = CGFloat(width)
    let h = CGFloat(height)

    // 1. Modern Desktop Wallpaper Background
    let bgRect = NSRect(x: 0, y: 0, width: w, height: h)
    let bgGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.20, alpha: 1.0),
        NSColor(calibratedRed: 0.08, green: 0.09, blue: 0.14, alpha: 1.0)
    ])
    bgGradient?.draw(in: bgRect, angle: -45)

    // Aurora Glow Orbs
    let orb1 = NSBezierPath(ovalIn: NSRect(x: 80, y: 180, width: 340, height: 260))
    NSColor.systemPurple.withAlphaComponent(0.18).setFill()
    orb1.fill()

    let orb2 = NSBezierPath(ovalIn: NSRect(x: 420, y: 80, width: 320, height: 240))
    NSColor.systemBlue.withAlphaComponent(0.15).setFill()
    orb2.fill()

    // 2. Menu Bar Simulator
    let menuBarRect = NSRect(x: 0, y: h - 28, width: w, height: 28)
    NSColor.black.withAlphaComponent(0.40).setFill()
    menuBarRect.fill()

    // Menu Bar App Item
    let appTitle = "FloatNotes  (2)"
    let menuAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: NSColor.white.withAlphaComponent(0.95)
    ]
    appTitle.draw(at: NSPoint(x: w - 130, y: h - 21), withAttributes: menuAttrs)

    // 3. Floating Apple Glass Sticky Note Card
    let cardW: CGFloat = 320
    let cardH: CGFloat = 260
    let cardX: CGFloat = 60 + CGFloat(animStep * 6)
    let cardY: CGFloat = 100 - CGFloat(animStep * 4)
    let cardRect = NSRect(x: cardX, y: cardY, width: cardW, height: cardH)

    // Drop Shadow
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowOffset = NSSize(width: 0, height: -8)
    shadow.shadowBlurRadius = 24
    shadow.set()

    // Card Glass Body
    let cardPath = NSBezierPath(roundedRect: cardRect, xRadius: 18, yRadius: 18)
    NSColor(calibratedRed: 0.98, green: 0.90, blue: 0.50, alpha: 0.88).setFill()
    cardPath.fill()

    // Reset shadow
    NSShadow().set()

    // Glass Specular Rim Border
    NSColor.white.withAlphaComponent(0.70).setStroke()
    cardPath.lineWidth = 1.2
    cardPath.stroke()

    // Top Header Buttons
    let pinSymbol = "📌 Always On Top"
    pinSymbol.draw(at: NSPoint(x: cardX + 16, y: cardY + cardH - 32), withAttributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.25, alpha: 0.8)
    ])

    // Status Pill
    let statusPillRect = NSRect(x: cardX + cardW - 88, y: cardY + cardH - 34, width: 72, height: 20)
    let statusPath = NSBezierPath(roundedRect: statusPillRect, xRadius: 10, yRadius: 10)
    NSColor.systemOrange.withAlphaComponent(0.20).setFill()
    statusPath.fill()
    "● doing".draw(at: NSPoint(x: cardX + cardW - 76, y: cardY + cardH - 30), withAttributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .bold),
        .foregroundColor: NSColor.systemOrange
    ])

    // Card Title
    title.draw(at: NSPoint(x: cardX + 16, y: cardY + cardH - 68), withAttributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
    ])

    // Card Body
    let bodyRect = NSRect(x: cardX + 16, y: cardY + 44, width: cardW - 32, height: cardH - 120)
    let bodyStyle = NSMutableParagraphStyle()
    bodyStyle.lineSpacing = 4
    bodyText.draw(in: bodyRect, withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor(calibratedRed: 0.20, green: 0.20, blue: 0.24, alpha: 0.95),
        .paragraphStyle: bodyStyle
    ])

    // Card Footer Bar
    let footerRect = NSRect(x: cardX + 16, y: cardY + 12, width: cardW - 32, height: 26)
    "☑ Checklist   • Bullet   🎤 Voice   doc.on.doc Copy".draw(at: NSPoint(x: footerRect.origin.x, y: footerRect.origin.y + 4), withAttributes: [
        .font: NSFont.systemFont(ofSize: 9, weight: .medium),
        .foregroundColor: NSColor(calibratedRed: 0.3, green: 0.3, blue: 0.35, alpha: 0.75)
    ])

    // Send to AI Pill
    let aiPillRect = NSRect(x: cardX + cardW - 86, y: cardY + 10, width: 70, height: 22)
    let aiPath = NSBezierPath(roundedRect: aiPillRect, xRadius: 11, yRadius: 11)
    NSColor.white.withAlphaComponent(0.35).setFill()
    aiPath.fill()
    NSColor.white.withAlphaComponent(0.70).setStroke()
    aiPath.lineWidth = 1
    aiPath.stroke()
    "✨ Send AI".draw(at: NSPoint(x: cardX + cardW - 78, y: cardY + 14), withAttributes: [
        .font: NSFont.systemFont(ofSize: 10, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.15, green: 0.15, blue: 0.2, alpha: 0.9)
    ])

    // 4. Feature Callout Card on the Right Side
    let featW: CGFloat = 340
    let featH: CGFloat = 280
    let featX: CGFloat = w - featW - 40
    let featY: CGFloat = 80
    let featRect = NSRect(x: featX, y: featY, width: featW, height: featH)

    let featPath = NSBezierPath(roundedRect: featRect, xRadius: 16, yRadius: 16)
    NSColor.white.withAlphaComponent(0.08).setFill()
    featPath.fill()
    NSColor.white.withAlphaComponent(0.20).setStroke()
    featPath.lineWidth = 1
    featPath.stroke()

    "FloatNotes Highlights".draw(at: NSPoint(x: featX + 18, y: featY + featH - 34), withAttributes: [
        .font: NSFont.systemFont(ofSize: 14, weight: .bold),
        .foregroundColor: NSColor.white
    ])

    let featuresList = """
    ✦ Apple Glass frosted blur & specular rims
    ✦ Multi-column Stacking (auto-wraps on screen)
    ✦ Compact Rectangle preset (300 x 150 pt)
    ✦ Clickable checklists: [ ] → [x]
    ✦ AI Dispatch: Gemini, ChatGPT, Claude, Perplexity
    ✦ macOS Writing Tools & Voice Dictation
    ✦ Keyboard shortcuts: ⌘N, ⇧⌘O, ⇧⌘S, ⌘+, ⌘-
    """
    let featStyle = NSMutableParagraphStyle()
    featStyle.lineSpacing = 5
    featuresList.draw(in: NSRect(x: featX + 18, y: featY + 20, width: featW - 36, height: featH - 65), withAttributes: [
        .font: NSFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.white.withAlphaComponent(0.85),
        .paragraphStyle: featStyle
    ])

    image.unlockFocus()
    return image
}

func exportMP4(frames: [NSImage], outputURL: URL, width: Int, height: Int) {
    guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else { return }

    let videoSettings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height
    ]

    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: writerInput, sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height
    ])

    writer.add(writerInput)
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let fps: Int32 = 2
    var frameIndex: Int64 = 0

    // Repeat each frame for 2 seconds to make it comfortable to read
    for frame in frames {
        guard let pixelBuffer = newPixelBufferFrom(image: frame, width: width, height: height) else { continue }
        for _ in 0..<4 {
            let presentTime = CMTime(value: frameIndex, timescale: fps)
            while !writerInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            adaptor.append(pixelBuffer, withPresentationTime: presentTime)
            frameIndex += 1
        }
    }

    writerInput.markAsFinished()
    let semaphore = DispatchSemaphore(value: 0)
    writer.finishWriting {
        semaphore.signal()
    }
    semaphore.wait()
    print("[DemoGenerator] Successfully generated MP4 video: \(outputURL.path)")
}

func newPixelBufferFrom(image: NSImage, width: Int, height: Int) -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer?
    let attrs = [
        kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue!,
        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue!
    ] as CFDictionary

    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
    guard let buffer = pixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, [])
    let pxData = CVPixelBufferGetBaseAddress(buffer)
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()

    if let context = CGContext(
        data: pxData,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
        space: rgbColorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    ) {
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    CVPixelBufferUnlockBaseAddress(buffer, [])
    return buffer
}

createDemoMedia()
