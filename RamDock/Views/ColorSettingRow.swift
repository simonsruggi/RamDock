import SwiftUI

/// "Automatic" or a custom color picked by the user, stored as a hex string ("" = automatic).
struct ColorSettingRow: View {
    let title: String
    let automaticLabel: String
    @Binding var hex: String

    var body: some View {
        HStack {
            Picker(title, selection: Binding(
                get: { !hex.isEmpty },
                set: { hex = $0 ? (hex.isEmpty ? "#FFFFFF" : hex) : "" }
            )) {
                Text(automaticLabel).tag(false)
                Text("Custom").tag(true)
            }
            if !hex.isEmpty {
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: NSColor(hex: hex) ?? .white) },
                    set: { hex = NSColor($0).hexString }
                ), supportsOpacity: false)
                .labelsHidden()
            }
        }
    }
}
