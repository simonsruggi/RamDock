import AppKit

/// Tools RamDock exposes over MCP. Each call samples the system on the spot: RamDock keeps no history.
enum RamDockTools {
    static func server() -> MCPServer {
        MCPServer(
            name: "ramdock",
            instructions: "Live RAM and CPU usage of this Mac and of its processes. Read-only: it cannot quit processes.",
            tools: [systemUsage, topProcesses]
        )
    }

    private static let systemUsage = MCPTool(
        name: "get_system_usage",
        description: "Current memory (used, total, swap) and CPU usage of this Mac, plus model, chip, macOS version, uptime and free disk space.",
        inputSchema: ["type": "object", "properties": [String: Any]()],
        handler: { _ in
            let stats = SystemStats()
            _ = stats.cpuUsage()
            Thread.sleep(forTimeInterval: 1)
            let cpu = stats.cpuUsage()
            let memoryPercent = stats.memoryUsage()
            let info = MacInfo.load()
            let totalGB = Double(info.memoryBytes) / 1_073_741_824
            var result: [String: Any] = [
                "memory_used_percent": round1(memoryPercent),
                "memory_used_gb": round1(totalGB * memoryPercent / 100),
                "memory_total_gb": round1(totalGB),
                "cpu_percent": round1(cpu),
                "cpu_cores": info.cpuCores,
                "model": info.model,
                "chip": info.chip,
                "macos": info.macOS,
                "uptime_hours": round1(info.uptime / 3600),
                "disk_free_gb": round1(Double(info.diskFree) / 1_000_000_000),
                "disk_total_gb": round1(Double(info.diskTotal) / 1_000_000_000),
            ]
            if let swap = swapUsage() {
                result["swap_used_gb"] = round1(swap.used)
                result["swap_total_gb"] = round1(swap.total)
            }
            return result
        }
    )

    private static let topProcesses = MCPTool(
        name: "list_top_processes",
        description: "The processes using the most memory or CPU right now. Memory is the physical footprint, the same number Activity Monitor shows; CPU is measured over one second, where 100 means one full core.",
        inputSchema: [
            "type": "object",
            "properties": [
                "sort_by": ["type": "string", "enum": ["memory", "cpu"], "default": "memory"],
                "limit": ["type": "integer", "minimum": 1, "maximum": 50, "default": 10],
                "apps_only": ["type": "boolean", "default": false,
                              "description": "Only apps with a Dock icon, without background processes"],
            ],
        ],
        handler: { args in
            let sortBy = args.string("sort_by") ?? "memory"
            guard sortBy == "memory" || sortBy == "cpu" else { throw MCPToolError("sort_by must be memory or cpu") }
            let limit = args.int("limit", default: 10, range: 1...50)
            let appsOnly = args["apps_only"] as? Bool ?? false

            let apps = Dictionary(NSWorkspace.shared.runningApplications.map {
                ($0.processIdentifier, (name: $0.localizedName, isApp: $0.activationPolicy == .regular))
            }, uniquingKeysWith: { first, _ in first })
            let sampler = ProcessSampler()
            _ = sampler.sample(apps: apps)
            Thread.sleep(forTimeInterval: 1)
            var entries = sampler.sample(apps: apps)
            if appsOnly { entries = entries.filter(\.isApp) }
            entries.sort { sortBy == "cpu" ? $0.cpu > $1.cpu : $0.memory > $1.memory }

            return ["processes": entries.prefix(limit).map {
                [
                    "pid": Int($0.pid),
                    "name": $0.name,
                    "memory_mb": Int($0.memory / 1_048_576),
                    "cpu_percent": round1($0.cpu),
                    "is_app": $0.isApp,
                ] as [String: Any]
            }]
        }
    )

    private static func swapUsage() -> (used: Double, total: Double)? {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else { return nil }
        return (Double(usage.xsu_used) / 1_073_741_824, Double(usage.xsu_total) / 1_073_741_824)
    }

    /// Decimal so that JSON shows 21.6 and not 21.600000000000001.
    private static func round1(_ value: Double) -> Decimal { Decimal(string: String(format: "%.1f", value)) ?? 0 }
}
