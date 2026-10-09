import AppKit
import Darwin

/// Reads CPU time and memory footprint of every process readable by the current
/// user via libproc. CPU % is the delta of user+system time between two samples,
/// so the first sample of a new process shows 0.
final class ProcessSampler {
    private(set) var entries: [ProcessEntry] = []
    var onUpdate: (() -> Void)?

    private struct Sample { let cpuNanos: UInt64; let startTime: UInt64 }

    private var previous: [pid_t: Sample] = [:]
    private var previousWall: UInt64 = 0
    private var names: [pid_t: (start: UInt64, name: String, isApp: Bool)] = [:]
    private var timer: Timer?
    private let queue = DispatchQueue(label: "ramdock.sampler", qos: .utility)
    private let timebase: (numer: UInt64, denom: UInt64) = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return (UInt64(info.numer), UInt64(info.denom))
    }()

    func start(interval: TimeInterval = 2) {
        guard timer == nil else { return }
        refresh()
        // CPU % needs two samples: take the second one quickly so the list isn't all 0% on open.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.refresh() }
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in self?.refresh() }
        t.tolerance = interval * 0.25
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        // Free everything while the panel is closed; the next open starts clean.
        queue.async { [weak self] in
            guard let self else { return }
            self.previous = [:]
            self.previousWall = 0
            self.names = [:]
            DispatchQueue.main.async {
                self.entries = []
                IconCache.prune(keeping: [])
            }
        }
    }

    func refresh() {
        // One LaunchServices query per refresh for the ~100 registered apps; asking
        // NSRunningApplication(processIdentifier:) for each of ~600 pids left ~30 MB behind.
        let apps = Dictionary(NSWorkspace.shared.runningApplications.map {
            ($0.processIdentifier, (name: $0.localizedName, isApp: $0.activationPolicy == .regular))
        }, uniquingKeysWith: { first, _ in first })
        queue.async { [weak self] in
            guard let self else { return }
            let list = self.sample(apps: apps)
            DispatchQueue.main.async {
                self.entries = list
                self.onUpdate?()
            }
        }
    }

    private func sample(apps: [pid_t: (name: String?, isApp: Bool)]) -> [ProcessEntry] {
        let count = proc_listallpids(nil, 0)
        guard count > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(count) + 64)
        let filled = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard filled > 0 else { return [] }

        let wall = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        let wallDelta = previousWall > 0 ? Double(wall - previousWall) : 0
        var current: [pid_t: Sample] = [:]
        var result: [ProcessEntry] = []

        for pid in pids.prefix(Int(filled)) where pid > 0 {
            var info = rusage_info_v4()
            let ok = withUnsafeMutablePointer(to: &info) {
                $0.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) {
                    proc_pid_rusage(pid, RUSAGE_INFO_V4, $0)
                }
            }
            guard ok == 0 else { continue }

            let cpuNanos = (info.ri_user_time + info.ri_system_time) * timebase.numer / timebase.denom
            let start = info.ri_proc_start_abstime
            current[pid] = Sample(cpuNanos: cpuNanos, startTime: start)

            var cpu = 0.0
            if wallDelta > 0, let prev = previous[pid], prev.startTime == start, cpuNanos >= prev.cpuNanos {
                cpu = Double(cpuNanos - prev.cpuNanos) / wallDelta * 100
            }

            let label = name(for: pid, start: start, app: apps[pid])
            result.append(ProcessEntry(pid: pid, name: label.name, cpu: cpu,
                                       memory: info.ri_phys_footprint, isApp: label.isApp))
        }

        names = names.filter { current[$0.key] != nil }
        previous = current
        previousWall = wall
        return result
    }

    private func name(for pid: pid_t, start: UInt64, app: (name: String?, isApp: Bool)?) -> (name: String, isApp: Bool) {
        if let cached = names[pid], cached.start == start { return (cached.name, cached.isApp) }
        var resolved: String
        var isApp = false
        if let app, let n = app.name {
            resolved = n
            isApp = app.isApp
        } else {
            var buf = [CChar](repeating: 0, count: Int(MAXPATHLEN))
            if proc_pidpath(pid, &buf, UInt32(buf.count)) > 0 {
                resolved = (String(cString: buf) as NSString).lastPathComponent
            } else {
                var short = [CChar](repeating: 0, count: 64)
                proc_name(pid, &short, UInt32(short.count))
                resolved = String(cString: short)
            }
            if resolved.isEmpty { resolved = "pid \(pid)" }
        }
        names[pid] = (start, resolved, isApp)
        return (resolved, isApp)
    }
}
