import Foundation

// MARK: - Metric Key

enum MetricKey: String, CaseIterable, Sendable, Identifiable {
    case cpu
    case memory
    case swap
    case thermal
    case battery
    case networkUp
    case networkDown
    case diskRead
    case diskWrite
    case diskFree

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cpu: "CPU"
        case .memory: "Memory"
        case .swap: "Swap"
        case .thermal: "Thermal"
        case .battery: "Battery"
        case .networkUp: "Upload"
        case .networkDown: "Download"
        case .diskRead: "Disk Read"
        case .diskWrite: "Disk Write"
        case .diskFree: "Disk Free"
        }
    }

    var menuBarLabel: String {
        switch self {
        case .cpu: "CPU"
        case .memory: "RAM"
        case .swap: "Swap"
        case .thermal: "Temp"
        case .battery: "Bat"
        case .networkUp: "↑"
        case .networkDown: "↓"
        case .diskRead: "Read"
        case .diskWrite: "Write"
        case .diskFree: "Disk"
        }
    }
}

// MARK: - Metric Result

enum MetricResult<Value: Sendable>: Sendable {
    case available(Value)
    case unavailable(String?)

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }
}

// MARK: - Typed Metric Values

struct CPUMetric: Sendable {
    let utilizationPercent: Double
}

struct MemoryMetric: Sendable {
    let usedBytes: UInt64
    let totalBytes: UInt64
    var utilizationPercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
}

struct SwapMetric: Sendable {
    let usedBytes: UInt64
    let totalBytes: UInt64
    var utilizationPercent: Double? {
        guard totalBytes > 0 else { return nil }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
}

enum ThermalState: Sendable, CaseIterable {
    case nominal
    case fair
    case serious
    case critical

    var displayName: String {
        switch self {
        case .nominal: "Normal"
        case .fair: "Elevated"
        case .serious: "Hot"
        case .critical: "Critical"
        }
    }
}

struct ThermalReading: Sendable {
    let state: ThermalState
    let temperatureCelsius: Double?

    var displayTemperature: String? {
        guard let temp = temperatureCelsius else { return nil }
        return String(format: "%.0f°C", temp)
    }

    var displayValue: String {
        if let temp = displayTemperature { return temp }
        return state.displayName
    }
}

struct BatteryMetric: Sendable {
    let chargePercent: Double
    let isCharging: Bool
    let timeToEmptyMinutes: Int?
    let timeToFullMinutes: Int?
}

struct NetworkMetric: Sendable {
    let bytesPerSecond: UInt64
}

struct DiskSpeedMetric: Sendable {
    let bytesPerSecond: UInt64
}

struct DiskCapacityMetric: Sendable {
    let freeBytes: UInt64
    let totalBytes: UInt64
    var usedBytes: UInt64 { totalBytes - freeBytes }
    var utilizationPercent: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100.0
    }
}

// MARK: - System Snapshot

struct SystemSnapshot: Sendable {
    let cpu: MetricResult<CPUMetric>
    let memory: MetricResult<MemoryMetric>
    let swap: MetricResult<SwapMetric>
    let thermal: MetricResult<ThermalReading>
    let battery: MetricResult<BatteryMetric>
    let networkUp: MetricResult<NetworkMetric>
    let networkDown: MetricResult<NetworkMetric>
    let diskRead: MetricResult<DiskSpeedMetric>
    let diskWrite: MetricResult<DiskSpeedMetric>
    let diskFree: MetricResult<DiskCapacityMetric>
    let timestamp: Date

    init(
        cpu: MetricResult<CPUMetric> = .unavailable(nil),
        memory: MetricResult<MemoryMetric> = .unavailable(nil),
        swap: MetricResult<SwapMetric> = .unavailable(nil),
        thermal: MetricResult<ThermalReading> = .unavailable(nil),
        battery: MetricResult<BatteryMetric> = .unavailable(nil),
        networkUp: MetricResult<NetworkMetric> = .unavailable(nil),
        networkDown: MetricResult<NetworkMetric> = .unavailable(nil),
        diskRead: MetricResult<DiskSpeedMetric> = .unavailable(nil),
        diskWrite: MetricResult<DiskSpeedMetric> = .unavailable(nil),
        diskFree: MetricResult<DiskCapacityMetric> = .unavailable(nil),
        timestamp: Date = Date()
    ) {
        self.cpu = cpu
        self.memory = memory
        self.swap = swap
        self.thermal = thermal
        self.battery = battery
        self.networkUp = networkUp
        self.networkDown = networkDown
        self.diskRead = diskRead
        self.diskWrite = diskWrite
        self.diskFree = diskFree
        self.timestamp = timestamp
    }

    func value(for key: MetricKey) -> String {
        let result: String
        switch key {
        case .cpu:
            result = formatPercent(cpu)
        case .memory:
            result = formatPercent(memory)
        case .swap:
            result = formatPercentOptional(swap)
        case .thermal:
            result = formatThermal(thermal)
        case .battery:
            result = formatBattery(battery)
        case .networkUp:
            result = formatRate(networkUp)
        case .networkDown:
            result = formatRate(networkDown)
        case .diskRead:
            result = formatRate(diskRead)
        case .diskWrite:
            result = formatRate(diskWrite)
        case .diskFree:
            result = formatCapacity(diskFree)
        }
        return result
    }

    private func formatPercent(_ result: MetricResult<CPUMetric>) -> String {
        switch result {
        case .available(let m):
            return String(format: "%.0f%%", m.utilizationPercent)
        case .unavailable:
            return "—"
        }
    }

    private func formatPercent(_ result: MetricResult<MemoryMetric>) -> String {
        switch result {
        case .available(let m):
            return String(format: "%.0f%%", m.utilizationPercent)
        case .unavailable:
            return "—"
        }
    }

    private func formatPercentOptional(_ result: MetricResult<SwapMetric>) -> String {
        switch result {
        case .available(let m):
            guard let pct = m.utilizationPercent else { return "—" }
            return String(format: "%.0f%%", pct)
        case .unavailable:
            return "—"
        }
    }

    private func formatThermal(_ result: MetricResult<ThermalReading>) -> String {
        switch result {
        case .available(let r):
            return r.displayValue
        case .unavailable:
            return "—"
        }
    }

    private func formatBattery(_ result: MetricResult<BatteryMetric>) -> String {
        switch result {
        case .available(let m):
            return "\(Int(m.chargePercent))%"
        case .unavailable:
            return "—"
        }
    }

    private func formatRate(_ result: MetricResult<NetworkMetric>) -> String {
        switch result {
        case .available(let m):
            return MetricCalculations.formatBytesPerSecond(m.bytesPerSecond)
        case .unavailable:
            return "—"
        }
    }

    private func formatRate(_ result: MetricResult<DiskSpeedMetric>) -> String {
        switch result {
        case .available(let m):
            return MetricCalculations.formatBytesPerSecond(m.bytesPerSecond)
        case .unavailable:
            return "—"
        }
    }

    private func formatCapacity(_ result: MetricResult<DiskCapacityMetric>) -> String {
        switch result {
        case .available(let m):
            return MetricCalculations.formatBytes(m.freeBytes) + " free"
        case .unavailable:
            return "—"
        }
    }
}
