import AppKit

/// A 16 pt color dot with an accent ring when selected.
final class SwatchView: NSView {
    enum Fill {
        case solid(NSColor)
        case systemAutomatic
        case loadAutomatic
        case custom(NSColor?)
    }

    var fill: Fill { didSet { needsDisplay = true } }
    var isSelected = false { didSet { needsDisplay = true } }
    var onClick: (() -> Void)?

    init(fill: Fill, help: String) {
        self.fill = fill
        super.init(frame: .zero)
        toolTip = help
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: 21).isActive = true
        heightAnchor.constraint(equalToConstant: 21).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func mouseDown(with event: NSEvent) { onClick?() }

    override func draw(_ dirtyRect: NSRect) {
        let dot = NSRect(x: 2.5, y: 2.5, width: 16, height: 16)
        let circle = NSBezierPath(ovalIn: dot)
        switch fill {
        case .solid(let color):
            color.setFill()
            circle.fill()
        case .systemAutomatic:
            NSGradient(colors: [.white, .black])?.draw(in: circle, angle: -45)
        case .loadAutomatic:
            Self.drawConic(in: dot, colors: [.systemGreen, .systemYellow, .systemOrange, .systemRed, .systemGreen])
        case .custom(let color):
            if let color {
                color.setFill()
                circle.fill()
            } else {
                Self.drawConic(in: dot, colors: [.systemRed, .systemYellow, .systemGreen, .systemCyan, .systemBlue, .systemPurple, .systemRed])
                if let plus = symbol("plus", size: 8, weight: .heavy)?.tinted(.white) {
                    plus.draw(in: NSRect(x: dot.midX - plus.size.width / 2, y: dot.midY - plus.size.height / 2,
                                         width: plus.size.width, height: plus.size.height))
                }
            }
        }
        NSColor.black.withAlphaComponent(0.15).setStroke()
        let border = NSBezierPath(ovalIn: dot.insetBy(dx: 0.5, dy: 0.5))
        border.lineWidth = 1
        border.stroke()

        if isSelected {
            NSColor.controlAccentColor.setStroke()
            let ring = NSBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
            ring.lineWidth = 2
            ring.stroke()
        }
    }

    /// AppKit has no angular gradient: approximate it with thin wedges.
    private static func drawConic(in rect: NSRect, colors: [NSColor]) {
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(ovalIn: rect).addClip()
        let center = NSPoint(x: rect.midX, y: rect.midY)
        let steps = 90
        let srgb = colors.compactMap { $0.usingColorSpace(.sRGB) }
        for i in 0..<steps {
            let t = CGFloat(i) / CGFloat(steps)
            let position = t * CGFloat(srgb.count - 1)
            let lower = Int(position), upper = min(lower + 1, srgb.count - 1)
            srgb[lower].blended(withFraction: position - CGFloat(lower), of: srgb[upper])?.setFill()
            let wedge = NSBezierPath()
            wedge.move(to: center)
            wedge.appendArc(withCenter: center, radius: rect.width, startAngle: 90 - t * 360,
                            endAngle: 90 - (t + 1.2 / CGFloat(steps)) * 360, clockwise: true)
            wedge.close()
            wedge.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
    }
}

extension NSImage {
    func tinted(_ color: NSColor) -> NSImage {
        NSImage(size: size, flipped: false) { rect in
            self.draw(in: rect)
            color.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
