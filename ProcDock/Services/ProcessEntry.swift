import AppKit

struct ProcessEntry: Identifiable, Equatable {
    let pid: pid_t
    let name: String
    let cpu: Double
    let memory: UInt64
    let isApp: Bool

    var id: pid_t { pid }
}

enum SortKey: String, CaseIterable, Identifiable {
    case cpu = "CPU"
    case memory = "RAM"
    var id: String { rawValue }
}
