import SwiftUI

@main
struct RamDockApp: App {
    @NSApplicationDelegateAdaptor(StatusBarController.self) private var statusBar

    var body: some Scene {
        Settings { EmptyView() }
    }
}
