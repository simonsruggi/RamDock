import AppKit

final class SpecTileView: RoundedBackgroundView {
    init(icon: String, title: String, value: String, detail: String?) {
        super.init(radius: 8, fill: .quaternaryLabelColor, fillOpacity: 0.6)

        let image = symbolView(icon, size: 13, weight: .medium, tint: .controlAccentColor)
        image.widthAnchor.constraint(equalToConstant: 18).isActive = true

        let valueLabel = makeLabel(value, size: 13, weight: .semibold, monospacedDigits: true)
        valueLabel.isSelectable = true
        var lines: [NSView] = [makeLabel(title, size: 10, color: .secondaryLabelColor), valueLabel]
        if let detail {
            let detailLabel = makeLabel(detail, size: 10, color: .secondaryLabelColor)
            detailLabel.lineBreakMode = .byTruncatingTail
            detailLabel.isSelectable = true
            lines.append(detailLabel)
        }
        let text = vStack(lines, spacing: 1)
        let row = hStack([image, text, spacer()], spacing: 8, insets: NSEdgeInsets(top: 9, left: 9, bottom: 9, right: 9),
                         alignment: .top)
        addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 62),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
}
