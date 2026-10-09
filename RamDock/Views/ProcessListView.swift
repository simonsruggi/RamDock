import SwiftUI

struct ProcessListView: View {
    let sampler: ProcessSampler
    @AppStorage("sortKey") private var sortKey: SortKey = .memory
    @State private var search = ""
    @State private var visible: [ProcessEntry] = []
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("", selection: $sortKey) {
                    ForEach(SortKey.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 110)
                TextField("Cerca", text: $search)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(10)
            Divider()
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(visible) { entry in
                        ProcessRowView(entry: entry) { force in kill(entry, force: force) }
                            .padding(.horizontal, 12)
                            .frame(height: 26)
                    }
                }
                .padding(.vertical, 4)
            }
            .defaultScrollAnchor(.top)
            Divider()
            HStack {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button("Esci") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .onAppear { sampler.start(); rebuild() }
        .onDisappear { sampler.stop() }
        .onChange(of: sampler.entries) { rebuild() }
        .onChange(of: sortKey) { rebuild() }
        .onChange(of: search) { rebuild() }
    }

    private func rebuild() {
        let query = search.trimmingCharacters(in: .whitespaces)
        var list = query.isEmpty ? sampler.entries
            : sampler.entries.filter { $0.name.localizedCaseInsensitiveContains(query) || String($0.pid) == query }
        switch sortKey {
        case .cpu: list.sort { ($0.cpu, $0.memory) > ($1.cpu, $1.memory) }
        case .memory: list.sort { $0.memory > $1.memory }
        }
        visible = list
        IconCache.prune(keeping: Set(sampler.entries.map(\.pid)))
    }

    private func kill(_ entry: ProcessEntry, force: Bool) {
        errorMessage = nil
        if let error = ProcessKiller.kill(entry.pid, force: force) {
            errorMessage = "\(entry.name): \(error)"
        } else {
            visible.removeAll { $0.pid == entry.pid }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { sampler.refresh() }
        }
    }
}
