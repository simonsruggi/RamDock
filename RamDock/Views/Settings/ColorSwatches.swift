import SwiftUI

/// One "automatic" swatch, a few presets and a free picker. Stores "" for automatic.
struct ColorSwatches: View {
    enum Automatic { case system, load }

    let automatic: Automatic
    @Binding var hex: String

    private static let presets = ["#FFFFFF", "#8E8E93", "#FFD60A", "#30D158", "#0A84FF", "#BF5AF2", "#FF375F"]

    var body: some View {
        HStack(spacing: 7) {
            swatch(selected: hex.isEmpty, help: automatic == .system ? "System" : "By load") { hex = "" } fill: {
                switch automatic {
                case .system:
                    Circle().fill(LinearGradient(colors: [.white, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                case .load:
                    Circle().fill(AngularGradient(colors: [.green, .yellow, .orange, .red, .green], center: .center))
                }
            }
            ForEach(Self.presets, id: \.self) { preset in
                swatch(selected: hex == preset, help: preset) { hex = preset } fill: {
                    Circle().fill(Color(nsColor: NSColor(hex: preset)!))
                }
            }
            let isCustom = !hex.isEmpty && !Self.presets.contains(hex)
            swatch(selected: isCustom, help: "Custom color") {
                ColorPanelBridge.shared.open(initial: NSColor(hex: hex) ?? .white) { hex = $0.hexString }
            } fill: {
                ZStack {
                    if isCustom, let color = NSColor(hex: hex) {
                        Circle().fill(Color(nsColor: color))
                    } else {
                        Circle().fill(AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], center: .center))
                        Image(systemName: "plus").font(.system(size: 8, weight: .heavy)).foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func swatch(selected: Bool, help: String, action: @escaping () -> Void,
                        @ViewBuilder fill: () -> some View) -> some View {
        Button(action: action) {
            fill()
                .frame(width: 16, height: 16)
                .overlay(Circle().strokeBorder(.black.opacity(0.15)))
                .padding(2.5)
                .overlay(Circle().strokeBorder(Color.accentColor, lineWidth: selected ? 2 : 0))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
