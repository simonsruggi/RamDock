import Foundation
import IOKit

struct MacInfo {
    let model: String
    let chip: String
    let cpuCores: String
    let gpu: String
    let memory: String
    let storage: String
    let macOS: String
    let uptime: String

    static func load() -> MacInfo {
        let process = ProcessInfo.processInfo
        let bytes = ByteCountFormatter()
        bytes.countStyle = .memory

        let chip = sysctlString("machdep.cpu.brand_string") ?? "—"
        var gpuName = chip
        var gpuCores: Int?
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AGXAccelerator"))
        if service != 0 {
            gpuCores = IORegistryEntryCreateCFProperty(service, "gpu-core-count" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? Int
            if let m = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String { gpuName = m }
            IOObjectRelease(service)
        }

        var storage = "—"
        if let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey]),
           let total = values.volumeTotalCapacity, let free = values.volumeAvailableCapacityForImportantUsage {
            let disk = ByteCountFormatter()
            disk.countStyle = .file
            storage = "\(disk.string(fromByteCount: free)) free of \(disk.string(fromByteCount: Int64(total)))"
        }

        let os = process.operatingSystemVersion
        let uptime = DateComponentsFormatter()
        uptime.allowedUnits = [.day, .hour, .minute]
        uptime.unitsStyle = .abbreviated

        return MacInfo(
            model: productName() ?? sysctlString("hw.model") ?? "Mac",
            chip: chip,
            cpuCores: cpuCoreSummary(total: process.processorCount),
            gpu: gpuCores.map { "\(gpuName), \($0) cores" } ?? gpuName,
            memory: bytes.string(fromByteCount: Int64(process.physicalMemory)),
            storage: storage,
            macOS: "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion) (\(sysctlString("kern.osversion") ?? "?"))",
            uptime: uptime.string(from: process.systemUptime) ?? "—"
        )
    }

    private static func cpuCoreSummary(total: Int) -> String {
        let levels = sysctlInt("hw.nperflevels") ?? 1
        guard levels > 1 else { return "\(total) cores" }
        let parts = (0..<levels).compactMap { i -> String? in
            guard let n = sysctlInt("hw.perflevel\(i).physicalcpu") else { return nil }
            return "\(n) \(sysctlString("hw.perflevel\(i).name") ?? "")".trimmingCharacters(in: .whitespaces)
        }
        return "\(total) cores (\(parts.joined(separator: " + ")))"
    }

    private static func productName() -> String? {
        let entry = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/product")
        guard entry != 0 else { return nil }
        defer { IOObjectRelease(entry) }
        guard let data = IORegistryEntryCreateCFProperty(entry, "product-name" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue() as? Data else { return nil }
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
