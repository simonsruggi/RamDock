import AppKit

/// Thin capsule filled by `fraction`, colored like the load scale.
final class StorageBarView: NSView {
    private let fraction: Double

    init(fraction: Double) {
        self.fraction = min(max(fraction, 0), 1)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 6).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func draw(_ dirtyRect: NSRect) {
        let r = bounds.height / 2
        NSColor.quaternaryLabelColor.setFill()
        NSBezierPath(roundedRect: bounds, xRadius: r, yRadius: r).fill()
        LoadColor.color(for: fraction * 100, kind: .memory).setFill()
        let filled = NSRect(x: 0, y: 0, width: bounds.width * fraction, height: bounds.height)
        NSBezierPath(roundedRect: filled, xRadius: r, yRadius: r).fill()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        needsDisplay = true
    }
}
