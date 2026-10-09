import SwiftUI

struct RootView: View {
    let sampler: ProcessSampler
    @State private var showingSettings = false

    var body: some View {
        if showingSettings {
            SettingsView { showingSettings = false }
        } else {
            ProcessListView(sampler: sampler) { showingSettings = true }
        }
    }
}
