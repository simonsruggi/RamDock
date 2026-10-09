import AppKit

/// Rounded rectangle drawn in draw(_:), so dynamic system colors follow light/dark mode.
/// `opacity` scales the color's own alpha (SwiftUI's `.quaternary.opacity(0.6)`).
class RoundedBackgroundView: NSView {
    var radius: CGFloat
    var fill: NSColor?
    var fillOpacity: CGFloat
    var stroke: NSColor?
    var strokeOpacity: CGFloat

    init(radius: CGFloat, fill: NSColor?, fillOpacity: CGFloat = 1, stroke: NSColor? = nil, strokeOpacity: CGFloat = 1) {
        self.radius = radius
        self.fill = fill
        self.fillOpacity = fillOpacity
        self.stroke = stroke
        self.strokeOpacity = strokeOpacity
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = bounds.insetBy(dx: 0.5, dy: 0.5)
        let r = min(radius, rect.height / 2, rect.width / 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: r, yRadius: r)
        if let fill {
            context.saveGState()
            context.setAlpha(fillOpacity)
            fill.setFill()
            path.fill()
            context.restoreGState()
        }
        if let stroke {
            context.saveGState()
            context.setAlpha(strokeOpacity)
            stroke.setStroke()
            path.lineWidth = 1
            path.stroke()
            context.restoreGState()
        }
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
