import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let inset = rect.insetBy(dx: 100, dy: 100)
    let path = NSBezierPath(roundedRect: inset, xRadius: 185, yRadius: 185)
    NSGradient(colors: [NSColor(calibratedRed: 0.13, green: 0.16, blue: 0.22, alpha: 1),
                        NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.09, alpha: 1)])!
        .draw(in: path, angle: -90)
    let bars: [(CGFloat, NSColor)] = [(0.35, .systemGreen), (0.6, .systemGreen), (0.85, .systemOrange), (0.5, .systemGreen)]
    let barWidth: CGFloat = 110, gap: CGFloat = 50
    var x = inset.midX - (CGFloat(bars.count) * barWidth + CGFloat(bars.count - 1) * gap) / 2
    for (h, color) in bars {
        let bar = NSRect(x: x, y: inset.minY + 150, width: barWidth, height: (inset.height - 300) * h)
        color.setFill()
        NSBezierPath(roundedRect: bar, xRadius: 24, yRadius: 24).fill()
        x += barWidth + gap
    }
    return true
}
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
