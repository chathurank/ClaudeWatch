#!/usr/bin/env swift

import Cocoa

// Icon generator for Claude Usage Bar
// Creates a gauge-style icon with Claude's orange/terracotta color

func createIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let scale = CGFloat(size) / 512.0

    // Background - rounded rectangle with gradient
    let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: 20 * scale, dy: 20 * scale),
                               xRadius: 90 * scale, yRadius: 90 * scale)

    // Claude's signature color - warm terracotta/coral
    let claudeOrange = NSColor(red: 0.85, green: 0.45, blue: 0.35, alpha: 1.0)
    let claudeDark = NSColor(red: 0.65, green: 0.30, blue: 0.25, alpha: 1.0)

    // Gradient background
    let gradient = NSGradient(starting: claudeOrange, ending: claudeDark)
    gradient?.draw(in: bgPath, angle: -45)

    // Center point
    let centerX = CGFloat(size) / 2
    let centerY = CGFloat(size) / 2 - 20 * scale

    // Gauge background arc (gray)
    let gaugeRadius = 160 * scale
    let gaugeWidth = 35 * scale

    let gaugeBgPath = NSBezierPath()
    gaugeBgPath.appendArc(withCenter: NSPoint(x: centerX, y: centerY),
                          radius: gaugeRadius,
                          startAngle: 180 + 45,
                          endAngle: 360 - 45,
                          clockwise: false)
    gaugeBgPath.lineWidth = gaugeWidth
    gaugeBgPath.lineCapStyle = .round
    NSColor(white: 1.0, alpha: 0.3).setStroke()
    gaugeBgPath.stroke()

    // Gauge value arc (white) - show ~65% filled
    let gaugeValuePath = NSBezierPath()
    let fillPercent: CGFloat = 0.65
    let startAngle: CGFloat = 180 + 45
    let endAngle: CGFloat = startAngle + (270 * fillPercent)

    gaugeValuePath.appendArc(withCenter: NSPoint(x: centerX, y: centerY),
                              radius: gaugeRadius,
                              startAngle: startAngle,
                              endAngle: endAngle,
                              clockwise: false)
    gaugeValuePath.lineWidth = gaugeWidth
    gaugeValuePath.lineCapStyle = .round
    NSColor.white.setStroke()
    gaugeValuePath.stroke()

    // Percentage text
    let percentText = "65%"
    let fontSize = 100 * scale
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white
    ]
    let textSize = percentText.size(withAttributes: attributes)
    let textRect = NSRect(x: centerX - textSize.width / 2,
                          y: centerY - textSize.height / 2 - 10 * scale,
                          width: textSize.width,
                          height: textSize.height)
    percentText.draw(in: textRect, withAttributes: attributes)

    // "Claude" label at bottom
    let labelText = "Claude"
    let labelFontSize = 50 * scale
    let labelFont = NSFont.systemFont(ofSize: labelFontSize, weight: .medium)
    let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: labelFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.9)
    ]
    let labelSize = labelText.size(withAttributes: labelAttributes)
    let labelRect = NSRect(x: centerX - labelSize.width / 2,
                           y: 60 * scale,
                           width: labelSize.width,
                           height: labelSize.height)
    labelText.draw(in: labelRect, withAttributes: labelAttributes)

    image.unlockFocus()

    return image
}

func saveIcon(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Created: \(path)")
    } catch {
        print("Failed to write: \(path) - \(error)")
    }
}

// Generate all required sizes for macOS app icon
let basePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let sizes = [16, 32, 64, 128, 256, 512, 1024]

for size in sizes {
    let image = createIcon(size: size)
    let filename = "icon_\(size)x\(size).png"
    saveIcon(image, to: "\(basePath)/\(filename)")
}

print("\nAll icons generated successfully!")
