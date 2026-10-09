import AppKit

func makeLabel(_ text: String, size: CGFloat, weight: NSFont.Weight = .regular,
               color: NSColor = .labelColor, monospacedDigits: Bool = false) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.font = monospacedDigits ? .monospacedDigitSystemFont(ofSize: size, weight: weight)
                                  : .systemFont(ofSize: size, weight: weight)
    label.textColor = color
    return label
}

func symbol(_ name: String, size: CGFloat, weight: NSFont.Weight = .regular) -> NSImage? {
    NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: size, weight: weight))
}

func symbolView(_ name: String, size: CGFloat, weight: NSFont.Weight = .regular,
                tint: NSColor = .secondaryLabelColor) -> NSImageView {
    let view = NSImageView(image: symbol(name, size: size, weight: weight) ?? NSImage())
    view.contentTintColor = tint
    return view
}

func hStack(_ views: [NSView], spacing: CGFloat, insets: NSEdgeInsets = NSEdgeInsetsZero,
            alignment: NSLayoutConstraint.Attribute = .centerY) -> NSStackView {
    let stack = NSStackView(views: views)
    stack.orientation = .horizontal
    stack.spacing = spacing
    stack.edgeInsets = insets
    stack.alignment = alignment
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}

func vStack(_ views: [NSView], spacing: CGFloat, insets: NSEdgeInsets = NSEdgeInsetsZero) -> NSStackView {
    let stack = NSStackView(views: views)
    stack.orientation = .vertical
    stack.spacing = spacing
    stack.edgeInsets = insets
    stack.alignment = .leading
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}

/// Flexible empty view that soaks up the extra space in a horizontal stack.
func spacer() -> NSView {
    let view = NSView()
    view.setContentHuggingPriority(.init(1), for: .horizontal)
    view.setContentCompressionResistancePriority(.init(1), for: .horizontal)
    return view
}

func separator() -> NSBox {
    let box = NSBox()
    box.boxType = .separator
    return box
}

func pinEdges(_ view: NSView, to container: NSView, insets: NSEdgeInsets = NSEdgeInsetsZero) {
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
        view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
        view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right),
        view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom),
    ])
}

/// Makes each view as wide as the stack's content area.
func fillWidth(_ views: [NSView], of stack: NSStackView) {
    for view in views {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalTo: stack.widthAnchor,
                                    constant: -(stack.edgeInsets.left + stack.edgeInsets.right)).isActive = true
    }
}

final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
