import SwiftUI

struct ProcessRowView: View {
    let entry: ProcessEntry
    let onKill: (_ force: Bool) -> Void
    @State private var hovering = false

    private static let bytes: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .memory
        f.allowedUnits = [.useMB, .useGB]
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: IconCache.icon(for: entry))
                .resizable()
                .frame(width: 18, height: 18)
            Text(entry.name)
                .lineLimit(1)
                .truncationMode(.middle)
                .help("PID \(entry.pid)")
            Spacer(minLength: 8)
            Text(String(format: "%.1f%%", entry.cpu))
                .frame(width: 58, alignment: .trailing)
                .foregroundStyle(entry.cpu >= 50 ? .red : .primary)
            Text(Self.bytes.string(fromByteCount: Int64(entry.memory)))
                .frame(width: 72, alignment: .trailing)
                .foregroundStyle(entry.memory >= 2 << 30 ? .red : .primary)
            Button { onKill(NSEvent.modifierFlags.contains(.option)) } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(hovering ? .red : .secondary)
            .help("Quit (⌥-click to force quit)")
        }
        .font(.system(size: 12).monospacedDigit())
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Quit") { onKill(false) }
            Button("Force Quit") { onKill(true) }
            Divider()
            Button("Copy PID") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(entry.pid)", forType: .string)
            }
        }
    }
}
