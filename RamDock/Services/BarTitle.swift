import AppKit

/// The status item text, also used by the live preview in Settings.
enum BarTitle {
    static func make(ram: Double, cpu: Double) -> NSAttributedString {
        let font = NSFont.monospacedDigitSystemFont(ofSize: BarStyle.fontSize, weight: .medium)
        let label: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: BarStyle.labelColor ?? .labelColor]
        let fixedValueColor = BarStyle.valueColor
        func value(_ v: Double, _ kind: LoadColor.Kind) -> NSAttributedString {
            NSAttributedString(string: String(format: "%.0f%%", v),
                               attributes: [.font: font, .foregroundColor: fixedValueColor ?? LoadColor.color(for: v, kind: kind)])
        }
        let display = BarDisplay.current
        let title = NSMutableAttributedString()
        if display != .cpu {
            title.append(NSAttributedString(string: "RAM ", attributes: label))
            title.append(value(ram, .memory))
        }
        if display != .memory {
            title.append(NSAttributedString(string: display == .both ? "  CPU " : "CPU ", attributes: label))
            title.append(value(cpu, .cpu))
        }
        return title
    }
}
