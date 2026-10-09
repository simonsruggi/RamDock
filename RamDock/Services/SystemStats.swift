import Foundation

/// System-wide RAM and CPU usage, cheap enough to poll every few seconds.
final class SystemStats {
    private var previousTicks: (busy: UInt64, total: UInt64)?
    private let totalMemory = Double(ProcessInfo.processInfo.physicalMemory)

    /// "Memory Used" as in Activity Monitor: app memory + wired + compressed.
    func memoryUsage() -> Double {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let appPages = UInt64(stats.internal_page_count) - UInt64(min(stats.purgeable_count, stats.internal_page_count))
        let used = Double(appPages + UInt64(stats.wire_count) + UInt64(stats.compressor_page_count)) * Double(vm_kernel_page_size)
        return min(used / totalMemory * 100, 100)
    }

    /// Average over all cores since the previous call (0 on the first one).
    func cpuUsage() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        let user = UInt64(info.cpu_ticks.0), system = UInt64(info.cpu_ticks.1)
        let idle = UInt64(info.cpu_ticks.2), nice = UInt64(info.cpu_ticks.3)
        let busy = user + system + nice
        let total = busy + idle
        defer { previousTicks = (busy, total) }
        guard let prev = previousTicks, total > prev.total else { return 0 }
        return Double(busy - prev.busy) / Double(total - prev.total) * 100
    }
}
