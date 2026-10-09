import SwiftUI

struct MacInfoCard: View {
    @State private var info: MacInfo?

    private static let english = Locale(identifier: "en_US")

    var body: some View {
        SettingsCard(title: "This Mac") {
            if let info {
                HStack(spacing: 10) {
                    Image(systemName: info.isLaptop ? "laptopcomputer" : "desktopcomputer")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(info.model).font(.system(size: 14, weight: .semibold))
                        Text("\(info.chip) · \(info.macOS)").font(.system(size: 11)).foregroundStyle(.secondary)
                    }
                }
                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    GridRow {
                        SpecTile(icon: "cpu", title: "CPU", value: "\(info.cpuCores) cores", detail: info.cpuBreakdown)
                        SpecTile(icon: "square.grid.3x3.fill", title: "GPU",
                                 value: info.gpuCores.map { "\($0) cores" } ?? info.gpuName,
                                 detail: info.gpuCores == nil ? nil : info.gpuName)
                    }
                    GridRow {
                        SpecTile(icon: "memorychip", title: "Memory", value: bytes(info.memoryBytes, .memory), detail: "Unified")
                        SpecTile(icon: "clock", title: "Uptime", value: uptime(info.uptime), detail: nil)
                    }
                }
                storage(info)
            } else {
                ProgressView().controlSize(.small).frame(maxWidth: .infinity)
            }
        }
        .textSelection(.enabled)
        .task { info = await Task.detached(priority: .utility) { MacInfo.load() }.value }
    }

    private func storage(_ info: MacInfo) -> some View {
        let used = max(info.diskTotal - info.diskFree, 0)
        let fraction = info.diskTotal > 0 ? Double(used) / Double(info.diskTotal) : 0
        return VStack(alignment: .leading, spacing: 5) {
            HStack {
                Label("Storage", systemImage: "internaldrive").font(.system(size: 11, weight: .medium))
                Spacer()
                Text("\(bytes(info.diskFree, .file)) free of \(bytes(info.diskTotal, .file))")
                    .font(.system(size: 11)).foregroundStyle(.secondary).monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.quaternary)
                    Capsule().fill(Color(nsColor: LoadColor.color(for: fraction * 100, kind: .memory)))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 6)
        }
    }

    private func bytes(_ value: Int64, _ style: ByteCountFormatStyle.Style) -> String {
        value.formatted(.byteCount(style: style).locale(Self.english))
    }

    private func uptime(_ seconds: TimeInterval) -> String {
        let f = DateComponentsFormatter()
        f.allowedUnits = seconds >= 86_400 ? [.day, .hour] : [.hour, .minute]
        f.unitsStyle = .abbreviated
        var calendar = Calendar.current
        calendar.locale = Self.english
        f.calendar = calendar
        return f.string(from: seconds) ?? "—"
    }
}
