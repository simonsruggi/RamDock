import SwiftUI

struct SettingsView: View {
    let onDone: () -> Void
    @AppStorage(BarDisplay.defaultsKey) private var barDisplay: BarDisplay = .both
    @AppStorage(BarStyle.fontSizeKey) private var fontSize = BarStyle.defaultFontSize
    @AppStorage(BarStyle.labelColorKey) private var labelColor = ""
    @AppStorage(BarStyle.valueColorKey) private var valueColor = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onDone) { Label("Processes", systemImage: "chevron.left") }
                    .buttonStyle(.borderless)
                Spacer()
                Text("Settings").font(.headline)
                Spacer()
                Color.clear.frame(width: 70, height: 1)
            }
            .padding(10)
            Divider()
            Form {
                Section("Menu bar") {
                    Picker("Show", selection: $barDisplay) {
                        ForEach(BarDisplay.allCases) { Text($0.label).tag($0) }
                    }
                    LabeledContent("Text size") {
                        HStack {
                            Slider(value: $fontSize, in: BarStyle.fontSizeRange, step: 1)
                            Text("\(Int(fontSize)) pt").monospacedDigit().frame(width: 40, alignment: .trailing)
                        }
                    }
                    ColorSettingRow(title: "Label color", automaticLabel: "System", hex: $labelColor)
                    ColorSettingRow(title: "Value color", automaticLabel: "By load", hex: $valueColor)
                }
                MacInfoSection()
            }
            .formStyle(.grouped)
        }
    }
}
