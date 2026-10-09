import Darwin

enum ProcessKiller {
    /// Returns nil on success, otherwise a short error message.
    static func kill(_ pid: pid_t, force: Bool) -> String? {
        guard pid != getpid() else { return "Non posso chiudere me stesso" }
        if Darwin.kill(pid, force ? SIGKILL : SIGTERM) == 0 { return nil }
        switch errno {
        case EPERM: return "Permesso negato: il processo appartiene a un altro utente"
        case ESRCH: return "Il processo non esiste più"
        default: return String(cString: strerror(errno))
        }
    }
}
