import Foundation

// MARK: - Injectable Source Protocols (for testing)

protocol CPUSampleSource: Sendable {
    func readCPUTicks() -> (user: UInt64, system: UInt64, idle: UInt64, total: UInt64)?
}

protocol MemorySampleSource: Sendable {
    func readMemoryInfo() -> (active: UInt64, inactive: UInt64, wired: UInt64, free: UInt64, pageSize: UInt64)?
}

protocol NetworkSampleSource: Sendable {
    func readNetworkCounters() -> (rxBytes: UInt64, txBytes: UInt64)?
}

// MARK: - Live Implementations

struct LiveCPUSampleSource: CPUSampleSource {
    func readCPUTicks() -> (user: UInt64, system: UInt64, idle: UInt64, total: UInt64)? {
        var size = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )
        var data = host_cpu_load_info_data_t()
        let result = withUnsafeMutablePointer(to: &data) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(
                    mach_host_self(),
                    HOST_CPU_LOAD_INFO,
                    $0,
                    &size
                )
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let user = UInt64(data.cpu_ticks.0)
        let system = UInt64(data.cpu_ticks.1)
        let idle = UInt64(data.cpu_ticks.2)
        let total = user + system + idle + UInt64(data.cpu_ticks.3)
        return (user: user, system: system, idle: idle, total: total)
    }
}

struct LiveMemorySampleSource: MemorySampleSource {
    func readMemoryInfo() -> (active: UInt64, inactive: UInt64, wired: UInt64, free: UInt64, pageSize: UInt64)? {
        var size = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        var data = vm_statistics64()
        let result = withUnsafeMutablePointer(to: &data) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(
                    mach_host_self(),
                    HOST_VM_INFO64,
                    $0,
                    &size
                )
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        let pageSize = UInt64(ProcessInfo.processInfo.activeProcessorCount > 0
            ? vm_kernel_page_size
            : 4096)
        return (
            active: UInt64(data.active_count) * pageSize,
            inactive: UInt64(data.inactive_count) * pageSize,
            wired: UInt64(data.wire_count) * pageSize,
            free: UInt64(data.free_count) * pageSize,
            pageSize: pageSize
        )
    }
}

struct LiveNetworkSampleSource: NetworkSampleSource {
    func readNetworkCounters() -> (rxBytes: UInt64, txBytes: UInt64)? {
        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = firstAddr
        while true {
            let flags = ptr.pointee.ifa_flags
            let name = String(cString: ptr.pointee.ifa_name)

            // Skip loopback, virtual, and inactive interfaces
            if (flags & UInt32(IFF_UP)) != 0,
               (flags & UInt32(IFF_RUNNING)) != 0,
               !name.hasPrefix("lo"),
               !name.hasPrefix("utun"),
               !name.hasPrefix("awdl"),
               !name.hasPrefix("bridge"),
               !name.hasPrefix("bond"),
               !name.hasPrefix("veth"),
               !name.hasPrefix("utap") {
                
                if let data = ptr.pointee.ifa_data {
                    let stats = data.withMemoryRebound(to: if_data.self, capacity: 1) { $0.pointee }
                    totalRx += UInt64(stats.ifi_ibytes)
                    totalTx += UInt64(stats.ifi_obytes)
                }
            }

            guard let next = ptr.pointee.ifa_next else {
                return (rxBytes: totalRx, txBytes: totalTx)
            }
            ptr = next
        }
    }
}
