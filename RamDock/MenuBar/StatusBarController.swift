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

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover)

        popover.behavior = .transient
        popover.contentSize = NSSize(width: 440, height: 520)
        popover.contentViewController = NSHostingController(rootView: ProcessListView(sampler: sampler))

        updateTitle()
        let t = Timer(timeInterval: 3, repeats: true) { [weak self] _ in self?.updateTitle() }
        t.tolerance = 0.5
        RunLoop.main.add(t, forMode: .common)
        timer = t
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

    private func updateTitle() {
        let ram = stats.memoryUsage()
        let cpu = stats.cpuUsage()
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let label: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        func value(_ v: Double, _ kind: LoadColor.Kind) -> NSAttributedString {
            NSAttributedString(string: String(format: "%.0f%%", v),
                               attributes: [.font: font, .foregroundColor: LoadColor.color(for: v, kind: kind)])
        }
        let title = NSMutableAttributedString(string: "RAM ", attributes: label)
        title.append(value(ram, .memory))
        title.append(NSAttributedString(string: "  CPU ", attributes: label))
        title.append(value(cpu, .cpu))
        statusItem.button?.attributedTitle = title
    }
}
