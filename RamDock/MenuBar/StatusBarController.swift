import AppKit

/// Status item with the live RAM/CPU percentages and the dropdown with the process list.
final class StatusBarController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var panel: DropdownPanel?
    private var outsideClickMonitor: Any?
    private let sampler = ProcessSampler()
    private let stats = SystemStats()
    private let readings = BarReadings()
    private var timer: Timer?
    private var lastTitle: NSAttributedString?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Updater.start()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePanel)

        sample()
        let t = Timer(timeInterval: 3, repeats: true) { [weak self] _ in self?.sample() }
        t.tolerance = 1
        RunLoop.main.add(t, forMode: .common)
        timer = t

        NotificationCenter.default.addObserver(self, selector: #selector(renderTitle),
                                               name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc private func togglePanel() {
        if panel != nil { closePanel() } else { openPanel() }
    }

    private func openPanel() {
        guard let button = statusItem.button else { return }
        // Built on every open and dropped on close, so a closed panel holds no memory.
        let panel = DropdownPanel(content: PanelViewController(sampler: sampler, readings: readings))
        panel.onCancel = { [weak self] in self?.closePanel() }
        self.panel = panel
        sampler.start()
        panel.show(below: button)
        // Clicks in other apps close it, like a menu; clicks in our own windows
        // (the panel itself, the color panel) are local events and don't.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePanel()
        }
    }

    private func closePanel() {
        guard let panel else { return }
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
        panel.orderOut(nil)
        self.panel = nil
        sampler.stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { malloc_zone_pressure_relief(nil, 0) }
    }

    private func sample() {
        readings.ram = stats.memoryUsage()
        readings.cpu = stats.cpuUsage()
        renderTitle()
        readings.onChange?()
    }

    @objc private func renderTitle() {
        let title = BarTitle.make(ram: readings.ram, cpu: readings.cpu)
        guard title != lastTitle else { return }
        lastTitle = title
        statusItem.button?.attributedTitle = title
    }
}
