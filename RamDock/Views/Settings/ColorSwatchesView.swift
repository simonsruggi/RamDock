import AppKit

/// One "automatic" swatch, a few presets and a custom one that opens the color panel.
/// Writes "" (automatic) or "#RRGGBB" to `defaultsKey`.
final class ColorSwatchesView: NSStackView {
    private static let presets = ["#FFFFFF", "#8E8E93", "#FFD60A", "#30D158", "#0A84FF", "#BF5AF2", "#FF375F"]

    private let defaultsKey: String
    private let automatic: SwatchView
    private var presetViews: [(hex: String, view: SwatchView)] = []
    private let custom = SwatchView(fill: .custom(nil), help: "Custom color")

    private var hex: String {
        get { UserDefaults.standard.string(forKey: defaultsKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    init(defaultsKey: String, loadBased: Bool) {
        self.defaultsKey = defaultsKey
        automatic = SwatchView(fill: loadBased ? .loadAutomatic : .systemAutomatic, help: loadBased ? "By load" : "System")
        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 7
        translatesAutoresizingMaskIntoConstraints = false

        automatic.onClick = { [weak self] in self?.hex = "" }
        addArrangedSubview(automatic)
        for preset in Self.presets {
            let view = SwatchView(fill: .solid(NSColor(hex: preset)!), help: preset)
            view.onClick = { [weak self] in self?.hex = preset }
            presetViews.append((preset, view))
            addArrangedSubview(view)
        }
        custom.onClick = { [weak self] in
            guard let self else { return }
            ColorPanelBridge.shared.open(initial: NSColor(hex: hex) ?? .white) { [weak self] in self?.hex = $0.hexString }
        }
        addArrangedSubview(custom)
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func refresh() {
        let current = hex
        let isCustom = !current.isEmpty && !Self.presets.contains(current)
        automatic.isSelected = current.isEmpty
        presetViews.forEach { $0.view.isSelected = $0.hex == current }
        custom.isSelected = isCustom
        custom.fill = .custom(isCustom ? NSColor(hex: current) : nil)
    }
}
