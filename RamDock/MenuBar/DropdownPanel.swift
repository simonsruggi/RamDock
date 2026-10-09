import AppKit

/// Translucent panel hanging under the status item. Used instead of NSPopover, whose
/// window keeps ~25 MB alive after the first open even when it shows an empty view.
final class DropdownPanel: NSPanel {
    static let size = NSSize(width: 440, height: 520)

    var onCancel: (() -> Void)?

    init(content: NSViewController) {
        super.init(contentRect: NSRect(origin: .zero, size: Self.size),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .transient]

        let background = NSVisualEffectView(frame: NSRect(origin: .zero, size: Self.size))
        // RAMDOCK_SCREENSHOT=1 renders an opaque panel for README screenshots, so
        // nothing on the desktop shows through the translucency.
        let screenshotMode = ProcessInfo.processInfo.environment["RAMDOCK_SCREENSHOT"] != nil
        background.material = screenshotMode ? .windowBackground : .popover
        background.blendingMode = screenshotMode ? .withinWindow : .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 12
        background.layer?.masksToBounds = true
        background.layer?.borderWidth = 0.5
        background.layer?.borderColor = NSColor.separatorColor.cgColor
        contentView = background

        contentViewController = nil
        background.addSubview(content.view)
        pinEdges(content.view, to: background)
        self.content = content
    }

    /// Keeps the view controller alive as long as the panel.
    private var content: NSViewController?

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) { onCancel?() }

    /// Centers the panel under `button`, kept inside the screen's visible area.
    func show(below button: NSStatusBarButton) {
        guard let buttonWindow = button.window else { return }
        let anchor = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let screen = buttonWindow.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        var x = anchor.midX - Self.size.width / 2
        x = min(max(x, screen.minX + 8), screen.maxX - Self.size.width - 8)
        setFrameOrigin(NSPoint(x: x, y: anchor.minY - Self.size.height - 6))
        makeKeyAndOrderFront(nil)
        invalidateShadow()
    }
}
