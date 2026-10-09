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
    case memory = "RAM"
    case cpu = "CPU"
    var id: String { rawValue }
}
