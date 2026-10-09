import SwiftUI

struct RootView: View {
    let sampler: ProcessSampler
    let readings: BarReadings
    @State private var showingSettings = false

    var body: some View {
        if showingSettings {
            SettingsView(readings: readings) { showingSettings = false }
        } else {
            ProcessListView(sampler: sampler) { showingSettings = true }
        }
    }
}
