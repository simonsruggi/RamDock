import SwiftUI

struct SettingsView: View {
    let readings: BarReadings
    let onDone: () -> Void
    @AppStorage(BarDisplay.defaultsKey) private var barDisplay: BarDisplay = .both
    @AppStorage(BarStyle.fontSizeKey) private var fontSize = BarStyle.defaultFontSize
    @AppStorage(BarStyle.labelColorKey) private var labelColor = ""
    @AppStorage(BarStyle.valueColorKey) private var valueColor = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Button(action: onDone) {
                    Image(systemName: "chevron.left").font(.system(size: 12, weight: .semibold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Back to processes")
                Text("Settings").font(.system(size: 13, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 44)
            Divider()
            ScrollView {
                VStack(spacing: 16) {
                    SettingsCard(title: "Menu bar") {
                        BarPreview(readings: readings, display: barDisplay, fontSize: fontSize,
                                   labelHex: labelColor, valueHex: valueColor)
                        SettingRow(label: "Show") {
                            Picker("", selection: $barDisplay) {
                                Text("Both").tag(BarDisplay.both)
                                Text("RAM").tag(BarDisplay.memory)
                                Text("CPU").tag(BarDisplay.cpu)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }
                        SettingRow(label: "Size") {
                            Image(systemName: "textformat.size.smaller").foregroundStyle(.secondary)
                            Slider(value: $fontSize, in: BarStyle.fontSizeRange, step: 1)
                                .controlSize(.small)
                            Image(systemName: "textformat.size.larger").foregroundStyle(.secondary)
                        }
                        SettingRow(label: "Labels") { ColorSwatches(automatic: .system, hex: $labelColor) }
                        SettingRow(label: "Values") { ColorSwatches(automatic: .load, hex: $valueColor) }
                    }
                    MacInfoCard()
                }
                .padding(14)
            }
            .defaultScrollAnchor(.top)
        }
    }
}
