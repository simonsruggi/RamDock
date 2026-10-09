import AppKit

/// "This Mac" card: model header, CPU/GPU/Memory/Uptime tiles and the disk bar.
/// The hardware is read off the main thread, a spinner shows meanwhile.
final class MacInfoCardView: NSView {
    private static let english = Locale(identifier: "en_US")
    private let card: SettingsCardView
    private let spinner = NSProgressIndicator()

    init() {
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.startAnimation(nil)
        let spinnerRow = hStack([spacer(), spinner, spacer()], spacing: 0)
        card = SettingsCardView(title: "This Mac", rows: [spinnerRow])
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)
        pinEdges(card, to: self)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let info = MacInfo.load()
            DispatchQueue.main.async { self?.show(info, replacing: spinnerRow) }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func show(_ info: MacInfo, replacing placeholder: NSView) {
        spinner.stopAnimation(nil)
        placeholder.removeFromSuperview()
        let rows = [header(info), tiles(info), storage(info)]
        rows.forEach(card.content.addArrangedSubview)
        fillWidth(rows, of: card.content)
    }

    private func header(_ info: MacInfo) -> NSView {
        let icon = symbolView(info.isLaptop ? "laptopcomputer" : "desktopcomputer", size: 26, weight: .light,
                              tint: .controlAccentColor)
        let model = makeLabel(info.model, size: 14, weight: .semibold)
        let subtitle = makeLabel("\(info.chip) · \(info.macOS)", size: 11, color: .secondaryLabelColor)
        [model, subtitle].forEach { $0.isSelectable = true }
        return hStack([icon, vStack([model, subtitle], spacing: 2), spacer()], spacing: 10)
    }

    private func tiles(_ info: MacInfo) -> NSView {
        let cpu = SpecTileView(icon: "cpu", title: "CPU", value: "\(info.cpuCores) cores", detail: info.cpuBreakdown)
        let gpu = SpecTileView(icon: "square.grid.3x3.fill", title: "GPU",
                               value: info.gpuCores.map { "\($0) cores" } ?? info.gpuName,
                               detail: info.gpuCores == nil ? nil : info.gpuName)
        let memory = SpecTileView(icon: "memorychip", title: "Memory", value: bytes(info.memoryBytes, .memory), detail: "Unified")
        let uptime = SpecTileView(icon: "clock", title: "Uptime", value: Self.uptime(info.uptime), detail: nil)

        let grid = NSGridView(views: [[cpu, gpu], [memory, uptime]])
        grid.rowSpacing = 8
        grid.columnSpacing = 8
        grid.xPlacement = .fill
        grid.yPlacement = .fill
        grid.translatesAutoresizingMaskIntoConstraints = false
        gpu.widthAnchor.constraint(equalTo: cpu.widthAnchor).isActive = true
        uptime.heightAnchor.constraint(equalTo: memory.heightAnchor).isActive = true
        gpu.heightAnchor.constraint(equalTo: cpu.heightAnchor).isActive = true
        return grid
    }

    private func storage(_ info: MacInfo) -> NSView {
        let used = max(info.diskTotal - info.diskFree, 0)
        let fraction = info.diskTotal > 0 ? Double(used) / Double(info.diskTotal) : 0

        let icon = symbolView("internaldrive", size: 11, tint: .labelColor)
        let title = makeLabel("Storage", size: 11, weight: .medium)
        let detail = makeLabel("\(bytes(info.diskFree, .file)) free of \(bytes(info.diskTotal, .file))",
                               size: 11, color: .secondaryLabelColor, monospacedDigits: true)
        detail.isSelectable = true
        let top = hStack([icon, title, spacer(), detail], spacing: 6)
        let bar = StorageBarView(fraction: fraction)
        let stack = vStack([top, bar], spacing: 5)
        fillWidth([top, bar], of: stack)
        return stack
    }

    private func bytes(_ value: Int64, _ style: ByteCountFormatStyle.Style) -> String {
        value.formatted(.byteCount(style: style).locale(Self.english))
    }

    private static func uptime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = seconds >= 86_400 ? [.day, .hour] : [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        var calendar = Calendar.current
        calendar.locale = english
        formatter.calendar = calendar
        return formatter.string(from: seconds) ?? "—"
    }
}
