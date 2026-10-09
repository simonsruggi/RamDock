import Foundation

enum BarDisplay: String, CaseIterable, Identifiable {
    case both, memory, cpu
    var id: String { rawValue }

    static let defaultsKey = "barDisplay"

    var label: String {
        switch self {
        case .both: "RAM and CPU"
        case .memory: "RAM only"
        case .cpu: "CPU only"
        }
    }

    static var current: BarDisplay {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(BarDisplay.init) ?? .both
    }
}
