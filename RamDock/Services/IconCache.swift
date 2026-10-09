import AppKit

/// App icons for the visible rows, flattened to one 18 pt @2x bitmap each: a full
/// app icon carries every size up to 1024 px.
enum IconCache {
    private static var icons: [pid_t: NSImage] = [:]
    private static let fallback = flatten(NSWorkspace.shared.icon(for: .unixExecutable))

    static func icon(for entry: ProcessEntry) -> NSImage {
        guard entry.isApp else { return fallback }
        if let cached = icons[entry.pid] { return cached }
        let image = NSRunningApplication(processIdentifier: entry.pid)?.icon.map(flatten) ?? fallback
        icons[entry.pid] = image
        return image
    }

    static func prune(keeping pids: Set<pid_t>) {
        icons = icons.filter { pids.contains($0.key) }
    }

    private static func flatten(_ image: NSImage) -> NSImage {
        let points = NSSize(width: 18, height: 18)
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 36, pixelsHigh: 36, bitsPerSample: 8,
                                         samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return image }
        rep.size = points
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        image.draw(in: NSRect(origin: .zero, size: points))
        NSGraphicsContext.restoreGraphicsState()
        let flat = NSImage(size: points)
        flat.addRepresentation(rep)
        return flat
    }
}
