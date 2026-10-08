import SwiftUI

@main
struct ProcDockApp: App {
    @State private var sampler = ProcessSampler()

    var body: some Scene {
        MenuBarExtra("ProcDock", systemImage: "cpu") {
            ProcessListView(sampler: sampler)
                .frame(width: 440, height: 520)
        }
        .menuBarExtraStyle(.window)
    }
}
