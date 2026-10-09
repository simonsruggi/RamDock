import AppKit

final class SettingsViewController: NSViewController {
    private let readings: BarReadings
    private let onDone: () -> Void

    private let preview: BarPreviewView
    private let showControl = NSSegmentedControl()
    private let sizeSlider = NSSlider()
    private let labelSwatches = ColorSwatchesView(defaultsKey: BarStyle.labelColorKey, loadBased: false)
    private let valueSwatches = ColorSwatchesView(defaultsKey: BarStyle.valueColorKey, loadBased: true)
    private static let displayOrder: [BarDisplay] = [.both, .memory, .cpu]

    init(readings: BarReadings, onDone: @escaping () -> Void) {
        self.readings = readings
        self.onDone = onDone
        preview = BarPreviewView(readings: readings)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    deinit { NotificationCenter.default.removeObserver(self) }

    override func loadView() {
        let root = vStack([header(), separator(), scrollingContent()], spacing: 0)
        root.distribution = .fill
        fillWidth(root.arrangedSubviews, of: root)
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        readings.onChange = { [weak self] in self?.preview.update() }
        NotificationCenter.default.addObserver(self, selector: #selector(defaultsChanged),
                                               name: UserDefaults.didChangeNotification, object: nil)
        syncControls()
    }

    // MARK: Layout

    private func header() -> NSView {
        let back = NSButton(image: symbol("chevron.left", size: 12, weight: .semibold) ?? NSImage(),
                            target: self, action: #selector(back))
        back.isBordered = false
        back.contentTintColor = .labelColor
        back.toolTip = "Back to processes"
        back.widthAnchor.constraint(equalToConstant: 22).isActive = true
        back.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let row = hStack([back, makeLabel("Settings", size: 13, weight: .semibold), spacer()], spacing: 6,
                         insets: NSEdgeInsets(top: 0, left: 10, bottom: 0, right: 10))
        row.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return row
    }

    private func scrollingContent() -> NSView {
        showControl.segmentCount = Self.displayOrder.count
        for (i, title) in ["Both", "RAM", "CPU"].enumerated() { showControl.setLabel(title, forSegment: i) }
        showControl.trackingMode = .selectOne
        showControl.target = self
        showControl.action = #selector(showChanged)

        sizeSlider.minValue = BarStyle.fontSizeRange.lowerBound
        sizeSlider.maxValue = BarStyle.fontSizeRange.upperBound
        sizeSlider.numberOfTickMarks = Int(BarStyle.fontSizeRange.upperBound - BarStyle.fontSizeRange.lowerBound) + 1
        sizeSlider.allowsTickMarkValuesOnly = true
        sizeSlider.controlSize = .small
        sizeSlider.target = self
        sizeSlider.action = #selector(sizeChanged)

        let menuBar = SettingsCardView(title: "Menu bar", rows: [
            preview,
            settingRow("Show", [showControl]),
            settingRow("Size", [symbolView("textformat.size.smaller", size: 12), sizeSlider,
                                symbolView("textformat.size.larger", size: 12)], expands: true),
            settingRow("Labels", [labelSwatches]),
            settingRow("Values", [valueSwatches]),
        ])
        let content = vStack([menuBar, MacInfoCardView()], spacing: 16,
                             insets: NSEdgeInsets(top: 14, left: 14, bottom: 14, right: 14))
        fillWidth(content.arrangedSubviews, of: content)

        let document = FlippedView()
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(content)
        pinEdges(content, to: document)

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.documentView = document
        NSLayoutConstraint.activate([
            document.topAnchor.constraint(equalTo: scroll.contentView.topAnchor),
            document.leadingAnchor.constraint(equalTo: scroll.contentView.leadingAnchor),
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
        ])
        scroll.setContentHuggingPriority(.init(1), for: .vertical)
        return scroll
    }

    // MARK: State

    private func syncControls() {
        showControl.selectedSegment = Self.displayOrder.firstIndex(of: BarDisplay.current) ?? 0
        sizeSlider.doubleValue = BarStyle.fontSize
        labelSwatches.refresh()
        valueSwatches.refresh()
        preview.update()
    }

    @objc private func defaultsChanged() { syncControls() }

    @objc private func back() { onDone() }

    @objc private func showChanged() {
        UserDefaults.standard.set(Self.displayOrder[showControl.selectedSegment].rawValue, forKey: BarDisplay.defaultsKey)
    }

    @objc private func sizeChanged() {
        UserDefaults.standard.set(sizeSlider.doubleValue.rounded(), forKey: BarStyle.fontSizeKey)
    }
}
