import AppKit

/// Green → yellow → red as the load goes from `calm` to `critical`.
enum LoadColor {
    enum Kind { case memory, cpu }

    static func color(for percent: Double, kind: Kind) -> NSColor {
        let (calm, critical): (Double, Double) = kind == .memory ? (50, 92) : (15, 85)
        let t = min(max((percent - calm) / (critical - calm), 0), 1)
        return NSColor(hue: 0.33 * (1 - t), saturation: 0.85, brightness: 0.9, alpha: 1)
    }
}
