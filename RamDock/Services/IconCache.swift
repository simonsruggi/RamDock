import AppKit

enum IconCache {
    private static var icons: [pid_t: NSImage] = [:]
    private static let fallback = NSWorkspace.shared.icon(for: .unixExecutable)

    static func icon(for entry: ProcessEntry) -> NSImage {
        guard entry.isApp else { return fallback }
        if let cached = icons[entry.pid] { return cached }
        let image = NSRunningApplication(processIdentifier: entry.pid)?.icon ?? fallback
        icons[entry.pid] = image
        return image
    }

    static func prune(keeping pids: Set<pid_t>) {
        icons = icons.filter { pids.contains($0.key) }
    }
}
