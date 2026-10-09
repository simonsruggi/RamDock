import AppKit

// Pure AppKit, no SwiftUI: SwiftUI keeps ~30 MB of caches alive after the panel's
// first open, while this whole app idles at ~11-15 MB.
let app = NSApplication.shared
let controller = StatusBarController()
app.delegate = controller
app.setActivationPolicy(.accessory)
app.run()
