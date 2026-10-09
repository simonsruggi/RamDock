import SwiftUI

/// Live replica of the status item, so changes are visible without looking up.
struct BarPreview: View {
    let readings: BarReadings
    let display: BarDisplay
    let fontSize: Double
    let labelHex: String
    let valueHex: String

    var body: some View {
        HStack(spacing: 0) {
            if display != .cpu { segment("RAM", readings.ram, .memory) }
            if display == .both { Spacer().frame(width: fontSize * 0.6) }
            if display != .memory { segment("CPU", readings.cpu, .cpu) }
        }
        .font(.system(size: fontSize, weight: .medium).monospacedDigit())
        .padding(.horizontal, 10)
        .frame(height: 30)
        .background(Capsule().fill(.quaternary))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .animation(.snappy(duration: 0.2), value: display)
    }

    private func segment(_ label: String, _ value: Double, _ kind: LoadColor.Kind) -> some View {
        HStack(spacing: fontSize * 0.3) {
            Text(label).foregroundStyle(NSColor(hex: labelHex).map { Color(nsColor: $0) } ?? .primary)
            Text(String(format: "%.0f%%", value))
                .foregroundStyle(Color(nsColor: NSColor(hex: valueHex) ?? LoadColor.color(for: value, kind: kind)))
                .contentTransition(.numericText())
        }
    }
}
