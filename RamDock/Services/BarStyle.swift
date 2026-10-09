import AppKit

/// Appearance of the menu bar title, stored in UserDefaults. An empty color
/// string means "automatic": system label color for labels, load color for values.
enum BarStyle {
    static let fontSizeKey = "barFontSize"
    static let labelColorKey = "barLabelColor"
    static let valueColorKey = "barValueColor"
    static let defaultFontSize = 12.0
    static let fontSizeRange = 9.0...18.0

    static var fontSize: Double {
        let v = UserDefaults.standard.double(forKey: fontSizeKey)
        return v == 0 ? defaultFontSize : min(max(v, fontSizeRange.lowerBound), fontSizeRange.upperBound)
    }

    static var labelColor: NSColor? { NSColor(hex: UserDefaults.standard.string(forKey: labelColorKey) ?? "") }
    static var valueColor: NSColor? { NSColor(hex: UserDefaults.standard.string(forKey: valueColorKey) ?? "") }
}

extension NSColor {
    convenience init?(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((v >> 16) & 0xFF) / 255, green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }

    var hexString: String {
        guard let c = usingColorSpace(.sRGB) else { return "" }
        return String(format: "#%02X%02X%02X", Int(round(c.redComponent * 255)),
                      Int(round(c.greenComponent * 255)), Int(round(c.blueComponent * 255)))
    }
}
