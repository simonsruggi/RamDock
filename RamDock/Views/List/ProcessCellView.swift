import AppKit

/// One process row: icon, name, CPU %, memory and the quit button (red while hovered).
final class ProcessCellView: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("ProcessCell")

    var onKill: ((_ force: Bool) -> Void)?

    private let icon = NSImageView()
    private let name = makeLabel("", size: 12, monospacedDigits: true)
    private let cpu = makeLabel("", size: 12, monospacedDigits: true)
    private let memory = makeLabel("", size: 12, monospacedDigits: true)
    private let killButton = NSButton()
    private var hovering = false { didSet { updateKillTint() } }

    private static let english = Locale(identifier: "en_US")
    private static let memoryStyle = ByteCountFormatStyle(style: .memory, allowedUnits: [.mb, .gb]).locale(english)

    override init(frame: NSRect) {
        super.init(frame: frame)
        identifier = Self.identifier

        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.widthAnchor.constraint(equalToConstant: 18).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 18).isActive = true

        name.lineBreakMode = .byTruncatingMiddle
        name.setContentCompressionResistancePriority(.init(10), for: .horizontal)
        name.setContentHuggingPriority(.init(1), for: .horizontal)

        cpu.alignment = .right
        cpu.widthAnchor.constraint(equalToConstant: 58).isActive = true
        memory.alignment = .right
        memory.widthAnchor.constraint(equalToConstant: 72).isActive = true

        killButton.image = symbol("xmark.circle.fill", size: 13)
        killButton.isBordered = false
        killButton.imagePosition = .imageOnly
        killButton.target = self
        killButton.action = #selector(killTapped)
        killButton.toolTip = "Quit (⌥-click to force quit)"
        updateKillTint()

        let row = hStack([icon, name, cpu, memory, killButton], spacing: 10,
                         insets: NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 12))
        row.setCustomSpacing(18, after: name)
        addSubview(row)
        pinEdges(row, to: self)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func configure(_ entry: ProcessEntry) {
        icon.image = IconCache.icon(for: entry)
        name.stringValue = entry.name
        name.toolTip = "PID \(entry.pid)"
        cpu.stringValue = String(format: "%.1f%%", entry.cpu)
        cpu.textColor = entry.cpu >= 50 ? .systemRed : .labelColor
        memory.stringValue = Int64(entry.memory).formatted(Self.memoryStyle)
        memory.textColor = entry.memory >= 2 << 30 ? .systemRed : .labelColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hovering = false
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { hovering = true }
    override func mouseExited(with event: NSEvent) { hovering = false }

    @objc private func killTapped() {
        onKill?(NSEvent.modifierFlags.contains(.option))
    }

    private func updateKillTint() {
        killButton.contentTintColor = hovering ? .systemRed : .secondaryLabelColor
    }
}
