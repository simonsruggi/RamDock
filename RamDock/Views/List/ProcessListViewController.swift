import AppKit

final class ProcessListViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate,
                                       NSTextFieldDelegate, NSMenuDelegate {
    private let sampler: ProcessSampler
    private let onSettings: () -> Void
    private var visible: [ProcessEntry] = []

    private let sortControl = NSSegmentedControl()
    private let searchField = NSTextField()
    private let table = NSTableView()
    private let errorLabel = makeLabel("", size: 11, color: .systemRed)

    private var sortKey: SortKey {
        get { UserDefaults.standard.string(forKey: "sortKey").flatMap(SortKey.init) ?? .memory }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "sortKey") }
    }

    init(sampler: ProcessSampler, onSettings: @escaping () -> Void) {
        self.sampler = sampler
        self.onSettings = onSettings
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func loadView() {
        let root = vStack([header(), separator(), tableScrollView(), separator(), footer()], spacing: 0)
        root.distribution = .fill
        fillWidth(root.arrangedSubviews, of: root)
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        sampler.onUpdate = { [weak self] in self?.rebuild() }
        rebuild()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(searchField)
    }

    // MARK: Layout

    private func header() -> NSView {
        sortControl.segmentCount = SortKey.allCases.count
        for (i, key) in SortKey.allCases.enumerated() { sortControl.setLabel(key.rawValue, forSegment: i) }
        sortControl.trackingMode = .selectOne
        sortControl.segmentDistribution = .fillEqually
        sortControl.selectedSegment = SortKey.allCases.firstIndex(of: sortKey) ?? 0
        sortControl.target = self
        sortControl.action = #selector(sortChanged)
        sortControl.widthAnchor.constraint(equalToConstant: 110).isActive = true

        searchField.placeholderString = "Search"
        searchField.bezelStyle = .roundedBezel
        searchField.delegate = self
        searchField.setContentHuggingPriority(.init(1), for: .horizontal)

        let gear = NSButton(image: symbol("gearshape", size: 13) ?? NSImage(), target: self, action: #selector(openSettings))
        gear.isBordered = false
        gear.contentTintColor = .labelColor
        gear.toolTip = "Settings"

        return hStack([sortControl, searchField, gear], spacing: 10,
                      insets: NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    }

    private func tableScrollView() -> NSView {
        let column = NSTableColumn(identifier: .init("process"))
        column.resizingMask = .autoresizingMask
        table.addTableColumn(column)
        table.headerView = nil
        table.rowHeight = 26
        table.intercellSpacing = .zero
        table.style = .plain
        table.selectionHighlightStyle = .none
        table.backgroundColor = .clear
        table.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        table.dataSource = self
        table.delegate = self

        let menu = NSMenu()
        menu.delegate = self
        table.menu = menu

        let scroll = NSScrollView()
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.automaticallyAdjustsContentInsets = false
        scroll.contentInsets = NSEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
        scroll.setContentHuggingPriority(.init(1), for: .vertical)
        return scroll
    }

    private func footer() -> NSView {
        errorLabel.maximumNumberOfLines = 2
        errorLabel.lineBreakMode = .byTruncatingTail
        errorLabel.setContentCompressionResistancePriority(.init(10), for: .horizontal)

        let quit = NSButton(title: "Quit", target: NSApp, action: #selector(NSApplication.terminate(_:)))
        quit.isBordered = false
        quit.font = .systemFont(ofSize: 11)
        quit.contentTintColor = .secondaryLabelColor

        errorLabel.alignment = .center
        errorLabel.setContentHuggingPriority(.init(1), for: .horizontal)
        return hStack([BrandView(), errorLabel, quit], spacing: 10,
                      insets: NSEdgeInsets(top: 7, left: 12, bottom: 7, right: 12))
    }

    // MARK: Data

    private func rebuild() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespaces)
        var list = query.isEmpty ? sampler.entries
            : sampler.entries.filter { $0.name.localizedCaseInsensitiveContains(query) || String($0.pid) == query }
        switch sortKey {
        case .cpu: list.sort { ($0.cpu, $0.memory) > ($1.cpu, $1.memory) }
        case .memory: list.sort { $0.memory > $1.memory }
        }
        visible = list
        table.reloadData()
        IconCache.prune(keeping: Set(sampler.entries.map(\.pid)))
    }

    func numberOfRows(in tableView: NSTableView) -> Int { visible.count }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: ProcessCellView.identifier, owner: nil) as? ProcessCellView
            ?? ProcessCellView(frame: .zero)
        let entry = visible[row]
        cell.configure(entry)
        cell.onKill = { [weak self] force in self?.kill(entry, force: force) }
        return cell
    }

    // MARK: Actions

    @objc private func sortChanged() {
        sortKey = SortKey.allCases[sortControl.selectedSegment]
        rebuild()
        table.scrollRowToVisible(0)
    }

    @objc private func openSettings() { onSettings() }

    func controlTextDidChange(_ obj: Notification) { rebuild() }

    private func kill(_ entry: ProcessEntry, force: Bool) {
        errorLabel.stringValue = ""
        if let error = ProcessKiller.kill(entry.pid, force: force) {
            errorLabel.stringValue = "\(entry.name): \(error)"
        } else {
            visible.removeAll { $0.pid == entry.pid }
            table.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.sampler.refresh() }
        }
    }

    // MARK: Context menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let row = table.clickedRow
        guard visible.indices.contains(row) else { return }
        let entry = visible[row]
        menu.addItem(ClosureMenuItem("Quit") { [weak self] in self?.kill(entry, force: false) })
        menu.addItem(ClosureMenuItem("Force Quit") { [weak self] in self?.kill(entry, force: true) })
        menu.addItem(.separator())
        menu.addItem(ClosureMenuItem("Copy PID") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString("\(entry.pid)", forType: .string)
        })
    }
}

final class ClosureMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
    }

    required init(coder: NSCoder) { fatalError("init(coder:) is not used") }

    @objc private func run() { handler() }
}
