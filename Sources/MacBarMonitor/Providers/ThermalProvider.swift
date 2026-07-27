import Foundation

// MARK: - Live Thermal Provider

struct LiveThermalProvider: ThermalProviding {
    func readThermal() async -> MetricResult<ThermalState> {
        let state = ProcessInfo.processInfo.thermalState
        let mapped: ThermalState
        switch state {
        case .nominal: mapped = .nominal
        case .fair: mapped = .fair
        case .serious: mapped = .serious
        case .critical: mapped = .critical
        @unknown default: mapped = .nominal
        }
        return .available(mapped)
    }
}

// MARK: - Testable Thermal Provider

struct TestableThermalProvider: ThermalProviding {
    let result: MetricResult<ThermalState>

    func readThermal() async -> MetricResult<ThermalState> {
        result
    }
}
