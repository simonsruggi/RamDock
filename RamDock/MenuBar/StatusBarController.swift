import AppKit
import SwiftUI

/// Status item with the live RAM/CPU percentages (an NSStatusItem rather than a
/// MenuBarExtra, which renders its label as a monochrome template and drops colors).
final class StatusBarController: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private let sampler = ProcessSampler()
    private let stats = SystemStats()
    private var timer: Timer?
    private let readings = BarReadings()
    private var lastTitle: NSAttributedString?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 440, height: 520)
        popover.delegate = self

        sample()
        let t = Timer(timeInterval: 3, repeats: true) { [weak self] _ in self?.sample() }
        t.tolerance = 1
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
            // Built on every open and dropped on close: a closed NSPopover keeps its
            // view alive, so SwiftUI's onDisappear never fires and nothing is freed.
            popover.contentViewController = NSHostingController(rootView: RootView(sampler: sampler, readings: readings))
            sampler.start()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
            NSApp.activate()
        }
    }

    func popoverDidClose(_ notification: Notification) {
        sampler.stop()
        popover.contentViewController = nil
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
        guard title != lastTitle else { return }
        lastTitle = title
        statusItem.button?.attributedTitle = title
    }
}
