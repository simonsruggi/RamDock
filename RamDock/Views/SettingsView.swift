import SwiftUI

struct SettingsView: View {
    let onDone: () -> Void
    @AppStorage(BarDisplay.defaultsKey) private var barDisplay: BarDisplay = .both

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
                Picker("Menu bar", selection: $barDisplay) {
                    ForEach(BarDisplay.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.radioGroup)
            }
            .formStyle(.grouped)
            Spacer()
        }
    }
}
