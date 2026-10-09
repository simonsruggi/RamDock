import SwiftUI

struct MacInfoSection: View {
    @State private var info: MacInfo?

    var body: some View {
        Section("This Mac") {
            if let info {
                LabeledContent("Model", value: info.model)
                LabeledContent("Chip", value: info.chip)
                LabeledContent("CPU", value: info.cpuCores)
                LabeledContent("GPU", value: info.gpu)
                LabeledContent("Memory", value: info.memory)
                LabeledContent("Storage", value: info.storage)
                LabeledContent("macOS", value: info.macOS)
                LabeledContent("Uptime", value: info.uptime)
            }
        }
        .textSelection(.enabled)
        .task { info = await Task.detached(priority: .utility) { MacInfo.load() }.value }
    }
}
