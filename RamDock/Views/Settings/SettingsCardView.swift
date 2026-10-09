import AppKit

/// Small uppercase caption over a rounded card, the building block of the settings page.
final class SettingsCardView: NSStackView {
    let content: NSStackView

    init(title: String, rows: [NSView]) {
        let caption = makeLabel("", size: 10, weight: .semibold, color: .secondaryLabelColor)
        caption.attributedStringValue = NSAttributedString(string: title.uppercased(), attributes: [
            .font: NSFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor,
            .kern: 0.6,
        ])
        let captionRow = hStack([caption], spacing: 0, insets: NSEdgeInsets(top: 0, left: 4, bottom: 0, right: 0))

        let card = RoundedBackgroundView(radius: 10, fill: .windowBackgroundColor, fillOpacity: 0.55,
                                         stroke: .separatorColor, strokeOpacity: 0.5)
        content = vStack(rows, spacing: 12, insets: NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
        card.addSubview(content)
        pinEdges(content, to: card)
        fillWidth(rows, of: content)

        super.init(frame: .zero)
        orientation = .vertical
        alignment = .leading
        spacing = 6
        translatesAutoresizingMaskIntoConstraints = false
        addArrangedSubview(captionRow)
        addArrangedSubview(card)
        card.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}

/// Fixed-width secondary label followed by a control; `expands` lets the control take the rest.
func settingRow(_ label: String, _ controls: [NSView], expands: Bool = false) -> NSStackView {
    let title = makeLabel(label, size: 12, color: .secondaryLabelColor)
    title.widthAnchor.constraint(equalToConstant: 58).isActive = true
    return hStack([title] + controls + (expands ? [] : [spacer()]), spacing: 12)
}
