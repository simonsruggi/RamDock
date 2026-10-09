import AppKit
import SwiftUI

/// Status item with the live RAM/CPU percentages (an NSStatusItem rather than a
/// MenuBarExtra, which renders its label as a monochrome template and drops colors).
final class StatusBarController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let sampler = ProcessSampler()
    private let stats = SystemStats()
    private var timer: Timer?
    private let readings = BarReadings()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 440, height: 520)
        popover.contentViewController = NSHostingController(rootView: RootView(sampler: sampler, readings: readings))

        sample()
        let t = Timer(timeInterval: 3, repeats: true) { [weak self] _ in self?.sample() }
        t.tolerance = 0.5
        RunLoop.main.add(t, forMode: .common)
        timer = t

        NotificationCenter.default.addObserver(self, selector: #selector(renderTitle),
                                               name: UserDefaults.didChangeNotification, object: nil)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate()
        }
    }

    private func sample() {
        readings.ram = stats.memoryUsage()
        readings.cpu = stats.cpuUsage()
        renderTitle()
    }

    @objc private func renderTitle() {
        let font = NSFont.monospacedDigitSystemFont(ofSize: BarStyle.fontSize, weight: .medium)
        let label: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: BarStyle.labelColor ?? .labelColor]
        let fixedValueColor = BarStyle.valueColor
        func value(_ v: Double, _ kind: LoadColor.Kind) -> NSAttributedString {
            NSAttributedString(string: String(format: "%.0f%%", v),
                               attributes: [.font: font, .foregroundColor: fixedValueColor ?? LoadColor.color(for: v, kind: kind)])
        }
        let display = BarDisplay.current
        let title = NSMutableAttributedString()
        if display != .cpu {
            title.append(NSAttributedString(string: "RAM ", attributes: label))
            title.append(value(readings.ram, .memory))
        }
        if display != .memory {
            title.append(NSAttributedString(string: display == .both ? "  CPU " : "CPU ", attributes: label))
            title.append(value(readings.cpu, .cpu))
        }
        statusItem.button?.attributedTitle = title
    }
}
