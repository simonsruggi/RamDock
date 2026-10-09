import Foundation
import IOKit

struct MacInfo {
    let model: String
    let isLaptop: Bool
    let chip: String
    let cpuCores: Int
    let cpuBreakdown: String?
    let gpuName: String
    let gpuCores: Int?
    let memoryBytes: Int64
    let diskTotal: Int64
    let diskFree: Int64
    let macOS: String
    let uptime: TimeInterval

    static func load() -> MacInfo {
        let process = ProcessInfo.processInfo
        let chip = sysctlString("machdep.cpu.brand_string") ?? "Unknown"
        let model = productName() ?? sysctlString("hw.model") ?? "Mac"

        var gpuName = chip
        var gpuCores: Int?
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AGXAccelerator"))
        if service != 0 {
            gpuCores = property(service, "gpu-core-count") as? Int
            if let m = property(service, "model") as? String { gpuName = m }
            IOObjectRelease(service)
        }

        let disk = try? URL(fileURLWithPath: "/").resourceValues(
            forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
        let os = process.operatingSystemVersion
        var version = "\(os.majorVersion).\(os.minorVersion)"
        if os.patchVersion > 0 { version += ".\(os.patchVersion)" }

        return MacInfo(
            model: model,
            isLaptop: model.localizedCaseInsensitiveContains("book"),
            chip: chip,
            cpuCores: process.processorCount,
            cpuBreakdown: cpuBreakdown(),
            gpuName: gpuName,
            gpuCores: gpuCores,
            memoryBytes: Int64(process.physicalMemory),
            diskTotal: Int64(disk?.volumeTotalCapacity ?? 0),
            diskFree: disk?.volumeAvailableCapacityForImportantUsage ?? 0,
            macOS: "macOS \(version) (\(sysctlString("kern.osversion") ?? "?"))",
            uptime: process.systemUptime
        )
    }

    /// "4 Super · 6 Efficiency" on chips with more than one core type.
    private static func cpuBreakdown() -> String? {
        let levels = sysctlInt("hw.nperflevels") ?? 1
        guard levels > 1 else { return nil }
        return (0..<levels).compactMap { i -> String? in
            guard let n = sysctlInt("hw.perflevel\(i).physicalcpu") else { return nil }
            return "\(n) \(sysctlString("hw.perflevel\(i).name") ?? "")".trimmingCharacters(in: .whitespaces)
        }.joined(separator: " · ")
    }

    private static func property(_ entry: io_registry_entry_t, _ key: String) -> Any? {
        IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    private static func productName() -> String? {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product")
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }
        guard let data = property(entry, "product-name") as? Data else { return nil }
        return String(decoding: data.prefix { $0 != 0 }, as: UTF8.self)
    }

    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buf = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buf, &size, nil, 0) == 0 else { return nil }
        return String(cString: buf)
    }

    private static func sysctlInt(_ name: String) -> Int? {
        var value: Int32 = 0
        var size = MemoryLayout<Int32>.size
        return sysctlbyname(name, &value, &size, nil, 0) == 0 ? Int(value) : nil
    }
}
