import AppKit

/// App icon + "RamDock" + version, the signature at the bottom of the panel.
final class BrandView: NSStackView {
    init() {
        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 16).isActive = true

        let name = makeLabel("RamDock", size: 12, weight: .semibold)
        let version = makeLabel(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
                                size: 11, color: .tertiaryLabelColor, monospacedDigits: true)

        super.init(frame: .zero)
        orientation = .horizontal
        spacing = 5
        alignment = .centerY
        translatesAutoresizingMaskIntoConstraints = false
        [icon, name, version].forEach(addArrangedSubview)
        setCustomSpacing(6, after: icon)
        setContentHuggingPriority(.required, for: .horizontal)
        toolTip = "RamDock — RAM and CPU in your menu bar"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}
