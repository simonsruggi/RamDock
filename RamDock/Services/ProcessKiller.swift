import Darwin

enum ProcessKiller {
    /// Returns nil on success, otherwise a short error message.
    static func kill(_ pid: pid_t, force: Bool) -> String? {
        guard pid != getpid() else { return "RamDock cannot quit itself" }
        if Darwin.kill(pid, force ? SIGKILL : SIGTERM) == 0 { return nil }
        switch errno {
        case EPERM: return "Permission denied: the process belongs to another user"
        case ESRCH: return "The process no longer exists"
        default: return String(cString: strerror(errno))
        }
    }
}
